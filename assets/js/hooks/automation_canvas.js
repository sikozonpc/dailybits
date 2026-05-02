const AutomationCanvas = {
  mounted() {
    this.canvas = this.el.querySelector("#automation-canvas");
    this.world = this.el.querySelector("#canvas-world");

    // Create SVG overlay for connection lines (sits above world, uses canvas coords)
    this.svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    this.svg.style.cssText =
      "position:absolute;inset:0;width:100%;height:100%;pointer-events:none;z-index:30;";
    this.canvas.prepend(this.svg);

    // Interaction state
    this.pan = { x: 0, y: 0 };
    this.panState = null;
    this._suppressNextClick = false;
    this.dragState = null;
    this.connectingFrom = null;
    this.tempPath = null;

    this.setupDragDrop();
    this.setupNodeInteractions();
    this.drawConnections();
  },

  updated() {
    if (this.dragState && !this.canvas.contains(this.dragState.nodeEl)) {
      this.dragState = null;
    }

    if (this.connectingFrom !== null) {
      if (!this.canvas.querySelector(`[data-node-id="${this.connectingFrom}"]`)) {
        this.cancelConnection();
      }
    }

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
        x: Math.round(e.clientX - rect.left - 110 - this.pan.x),
        y: Math.round(e.clientY - rect.top - 40 - this.pan.y),
      });
    });
  },

  setupSidebarDrag() {
    this.el.querySelectorAll("[data-node-type]").forEach((el) => {
      if (el._dragBound) return;
      el.addEventListener("dragstart", (e) => {
        e.dataTransfer.setData("node-type", el.dataset.nodeType);
        e.dataTransfer.effectAllowed = "copy";
        el.style.opacity = "0.6";
        setTimeout(() => (el.style.opacity = ""), 0);
      });
      el._dragBound = true;
    });
  },

  // ── Node interactions (click, drag, connect, pan) ───────────────────

  setupNodeInteractions() {
    this.canvas.addEventListener("click", (e) => {
      // Swallow click if it followed a pan gesture
      if (this._suppressNextClick) {
        this._suppressNextClick = false;
        return;
      }

      const port = e.target.closest("[data-port]");
      if (port) {
        this.handlePortClick(port, e);
        return;
      }

      const deleteBtn = e.target.closest("[data-delete-node]");
      if (deleteBtn) {
        const nodeId = parseInt(deleteBtn.closest("[data-node-id]").dataset.nodeId);
        this.pushEvent("delete_node", { id: nodeId });
        return;
      }

      const nodeEl = e.target.closest("[data-node-id]");
      if (nodeEl) {
        this.pushEvent("select_node", { id: parseInt(nodeEl.dataset.nodeId) });
        return;
      }

      if (this.connectingFrom !== null) {
        this.cancelConnection();
      } else {
        this.pushEvent("deselect", {});
      }
    });

    this.canvas.addEventListener("mousedown", (e) => {
      // Node drag handle
      const handle = e.target.closest("[data-node-drag]");
      if (handle && !e.target.closest("[data-delete-node]")) {
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
        return;
      }

      // Don't start panning from ports, delete buttons, or node bodies
      if (
        e.target.closest("[data-port]") ||
        e.target.closest("[data-delete-node]") ||
        e.target.closest("[data-node-id]")
      ) return;

      // Canvas background → start panning
      this.panState = {
        startX: e.clientX,
        startY: e.clientY,
        startPanX: this.pan.x,
        startPanY: this.pan.y,
        moved: false,
      };
      this.canvas.style.cursor = "grabbing";
      e.preventDefault();
    });

    this._onMouseMove = (e) => {
      // Pan
      if (this.panState) {
        const dx = e.clientX - this.panState.startX;
        const dy = e.clientY - this.panState.startY;
        if (Math.abs(dx) > 2 || Math.abs(dy) > 2) {
          this.panState.moved = true;
        }
        this.pan.x = this.panState.startPanX + dx;
        this.pan.y = this.panState.startPanY + dy;
        this.world.style.transform = `translate(${this.pan.x}px, ${this.pan.y}px)`;
        this.drawConnections();
        return;
      }

      // Node drag
      if (this.dragState) {
        const dx = e.clientX - this.dragState.startX;
        const dy = e.clientY - this.dragState.startY;
        this.dragState.nodeEl.style.left = `${this.dragState.startLeft + dx}px`;
        this.dragState.nodeEl.style.top = `${this.dragState.startTop + dy}px`;
        this.dragState.moved = true;
        this.drawConnections();
      }

      // Temp connection wire
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

    this._onMouseUp = (e) => {
      // End pan
      if (this.panState) {
        if (this.panState.moved) {
          this._suppressNextClick = true;
        }
        this.canvas.style.cursor = "";
        this.panState = null;
        return;
      }

      // End node drag
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

      // getBoundingClientRect() returns post-transform screen coords,
      // so subtracting the canvas rect gives correct canvas-relative positions.
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
      path.setAttribute("stroke", "oklch(0.65 0.18 260)");
      path.setAttribute("stroke-width", "2.5");
      path.setAttribute("stroke-dasharray", "6 4");
    } else {
      path.setAttribute("stroke", "oklch(0.55 0.2 260)");
      path.setAttribute("stroke-width", "2.5");
      path.classList.add("connection-flow");
    }

    return path;
  },
};

export default AutomationCanvas;
