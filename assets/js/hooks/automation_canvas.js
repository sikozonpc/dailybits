const AutomationCanvas = {
  mounted() {
    this.canvas = this.el.querySelector("#automation-canvas");

    // Create SVG overlay for connection lines
    this.svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    this.svg.style.cssText =
      "position:absolute;inset:0;width:100%;height:100%;pointer-events:none;z-index:5;";
    this.canvas.prepend(this.svg);

    // Interaction state
    this.dragState = null;
    this.connectingFrom = null;
    this.tempPath = null;

    this.setupDragDrop();
    this.setupNodeInteractions();
    this.drawConnections();
  },

  updated() {
    // If the dragged node was removed by LiveView, cancel drag
    if (this.dragState && !this.canvas.contains(this.dragState.nodeEl)) {
      this.dragState = null;
    }

    // If connecting-from node was removed, cancel connection
    if (this.connectingFrom !== null) {
      if (!this.canvas.querySelector(`[data-node-id="${this.connectingFrom}"]`)) {
        this.cancelConnection();
      }
    }

    // Re-attach sidebar drag listeners (LiveView may have patched DOM)
    this.setupSidebarDrag();
    this.drawConnections();
  },

  destroyed() {
    if (this._onMouseMove) document.removeEventListener("mousemove", this._onMouseMove);
    if (this._onMouseUp) document.removeEventListener("mouseup", this._onMouseUp);
    if (this._onKeyDown) document.removeEventListener("keydown", this._onKeyDown);
  },

  // ── Drag & Drop from sidebar ────────────────────────────────────────

  setupDragDrop() {
    this.setupSidebarDrag();

    this.canvas.addEventListener("dragover", (e) => {
      e.preventDefault();
      e.dataTransfer.dropEffect = "copy";
    });

    this.canvas.addEventListener("drop", (e) => {
      e.preventDefault();
      const type = e.dataTransfer.getData("node-type");
      if (!type) return;

      const rect = this.canvas.getBoundingClientRect();
      this.pushEvent("add_node", {
        type,
        x: Math.round(e.clientX - rect.left - 110),
        y: Math.round(e.clientY - rect.top - 40),
      });
    });
  },

  setupSidebarDrag() {
    this.el.querySelectorAll("[data-node-type]").forEach((el) => {
      if (el._dragBound) return;
      el.addEventListener("dragstart", (e) => {
        e.dataTransfer.setData("node-type", el.dataset.nodeType);
        e.dataTransfer.effectAllowed = "copy";
        // Add a subtle drag image effect
        el.style.opacity = "0.6";
        setTimeout(() => (el.style.opacity = ""), 0);
      });
      el._dragBound = true;
    });
  },

  // ── Node interactions (click, drag, connect) ────────────────────────

  setupNodeInteractions() {
    // Click handler on canvas
    this.canvas.addEventListener("click", (e) => {
      // Port click → connection
      const port = e.target.closest("[data-port]");
      if (port) {
        this.handlePortClick(port, e);
        return;
      }

      // Delete button
      const deleteBtn = e.target.closest("[data-delete-node]");
      if (deleteBtn) {
        const nodeId = parseInt(
          deleteBtn.closest("[data-node-id]").dataset.nodeId
        );
        this.pushEvent("delete_node", { id: nodeId });
        return;
      }

      // Node body → select
      const nodeEl = e.target.closest("[data-node-id]");
      if (nodeEl) {
        this.pushEvent("select_node", {
          id: parseInt(nodeEl.dataset.nodeId),
        });
        return;
      }

      // Canvas background
      if (this.connectingFrom !== null) {
        this.cancelConnection();
      } else {
        this.pushEvent("deselect", {});
      }
    });

    // Mousedown → start dragging a node
    this.canvas.addEventListener("mousedown", (e) => {
      const handle = e.target.closest("[data-node-drag]");
      if (!handle) return;
      if (e.target.closest("[data-delete-node]")) return;

      const nodeEl = handle.closest("[data-node-id]");

      this.dragState = {
        nodeId: parseInt(nodeEl.dataset.nodeId),
        startX: e.clientX,
        startY: e.clientY,
        startLeft: parseFloat(nodeEl.style.left),
        startTop: parseFloat(nodeEl.style.top),
        nodeEl,
        moved: false,
      };

      nodeEl.style.zIndex = "50";
      e.preventDefault();
    });

    // Mousemove → drag node / draw temp connection
    this._onMouseMove = (e) => {
      if (this.dragState) {
        const dx = e.clientX - this.dragState.startX;
        const dy = e.clientY - this.dragState.startY;
        this.dragState.nodeEl.style.left = `${this.dragState.startLeft + dx}px`;
        this.dragState.nodeEl.style.top = `${this.dragState.startTop + dy}px`;
        this.dragState.moved = true;
        this.drawConnections();
      }

      if (this.connectingFrom !== null && this.tempPath) {
        const rect = this.canvas.getBoundingClientRect();
        const x1 = parseFloat(this.tempPath.dataset.sx);
        const y1 = parseFloat(this.tempPath.dataset.sy);
        const x2 = e.clientX - rect.left;
        const y2 = e.clientY - rect.top;
        const cp = Math.max(Math.abs(x2 - x1) / 2, 50);
        this.tempPath.setAttribute(
          "d",
          `M ${x1} ${y1} C ${x1 + cp} ${y1}, ${x2 - cp} ${y2}, ${x2} ${y2}`
        );
      }
    };
    document.addEventListener("mousemove", this._onMouseMove);

    // Mouseup → finish drag
    this._onMouseUp = (e) => {
      if (!this.dragState) return;
      if (this.dragState.moved) {
        this.pushEvent("move_node", {
          id: this.dragState.nodeId,
          x: Math.round(parseFloat(this.dragState.nodeEl.style.left)),
          y: Math.round(parseFloat(this.dragState.nodeEl.style.top)),
        });
      }
      this.dragState.nodeEl.style.zIndex = "10";
      this.dragState = null;
    };
    document.addEventListener("mouseup", this._onMouseUp);

    // Escape → cancel connection
    this._onKeyDown = (e) => {
      if (e.key === "Escape" && this.connectingFrom !== null) {
        this.cancelConnection();
      }
    };
    document.addEventListener("keydown", this._onKeyDown);
  },

  // ── Port click → start / finish connection ──────────────────────────

  handlePortClick(port, e) {
    const nodeEl = port.closest("[data-node-id]");
    const nodeId = parseInt(nodeEl.dataset.nodeId);
    const type = port.dataset.port;

    if (type === "output" && this.connectingFrom === null) {
      // Start drawing a connection
      this.connectingFrom = nodeId;

      const rect = this.canvas.getBoundingClientRect();
      const pr = port.getBoundingClientRect();
      const x = pr.left + pr.width / 2 - rect.left;
      const y = pr.top + pr.height / 2 - rect.top;

      this.tempPath = this.makePath(x, y, x, y, true);
      this.tempPath.dataset.sx = x;
      this.tempPath.dataset.sy = y;
      this.svg.appendChild(this.tempPath);

      this.canvas.style.cursor = "crosshair";
      port.classList.add("border-primary", "bg-primary/20", "scale-125");
    } else if (
      type === "input" &&
      this.connectingFrom !== null &&
      this.connectingFrom !== nodeId
    ) {
      // Complete the connection
      this.pushEvent("connect_nodes", { from: this.connectingFrom, to: nodeId });
      this.cancelConnection();
    }

    e.stopPropagation();
  },

  cancelConnection() {
    if (this.tempPath) {
      this.tempPath.remove();
      this.tempPath = null;
    }
    this.canvas.querySelectorAll("[data-port].border-primary").forEach((p) => {
      p.classList.remove("border-primary", "bg-primary/20", "scale-125");
    });
    this.connectingFrom = null;
    this.canvas.style.cursor = "";
  },

  // ── SVG connection rendering ────────────────────────────────────────

  drawConnections() {
    // Clear existing connection paths (not the temp one)
    this.svg.querySelectorAll("path.conn").forEach((p) => p.remove());

    let connections;
    try {
      connections = JSON.parse(this.el.dataset.connections || "[]");
    } catch {
      return;
    }

    const cr = this.canvas.getBoundingClientRect();

    for (const c of connections) {
      const from = this.canvas.querySelector(
        `[data-node-id="${c.from}"] [data-port="output"]`
      );
      const to = this.canvas.querySelector(
        `[data-node-id="${c.to}"] [data-port="input"]`
      );
      if (!from || !to) continue;

      const fr = from.getBoundingClientRect();
      const tr = to.getBoundingClientRect();

      const x1 = fr.left + fr.width / 2 - cr.left;
      const y1 = fr.top + fr.height / 2 - cr.top;
      const x2 = tr.left + tr.width / 2 - cr.left;
      const y2 = tr.top + tr.height / 2 - cr.top;

      const path = this.makePath(x1, y1, x2, y2, false);
      path.classList.add("conn");
      this.svg.insertBefore(path, this.tempPath || null);
    }
  },

  makePath(x1, y1, x2, y2, isTemp) {
    const cp = Math.max(Math.abs(x2 - x1) / 2, 80);
    const d = `M ${x1} ${y1} C ${x1 + cp} ${y1}, ${x2 - cp} ${y2}, ${x2} ${y2}`;

    const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
    path.setAttribute("d", d);
    path.setAttribute("fill", "none");
    path.setAttribute("stroke-linecap", "round");

    if (isTemp) {
      path.setAttribute("stroke", "oklch(0.65 0.15 260 / 0.5)");
      path.setAttribute("stroke-width", "2");
      path.setAttribute("stroke-dasharray", "6 4");
    } else {
      path.setAttribute("stroke", "oklch(0.6 0.18 260)");
      path.setAttribute("stroke-width", "2.5");
      path.classList.add("connection-flow");
    }

    return path;
  },
};

export default AutomationCanvas;
