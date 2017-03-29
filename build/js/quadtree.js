var Quadtree;

Quadtree = (function() {
  var calculateDirection, getCenter, isOversized, observe, validateElement;

  function Quadtree(arg) {
    var child, that;
    this.x = arg.x, this.y = arg.y, this.width = arg.width, this.height = arg.height, this.maxElements = arg.maxElements;
    if ((this.width == null) || (this.height == null)) {
      throw new Error("Missing quadtree dimensions.");
    }
    if (this.x == null) {
      this.x = 0;
    }
    if (this.y == null) {
      this.y = 0;
    }
    if (this.maxElements == null) {
      this.maxElements = 1;
    }
    this.contents = [];
    this.oversized = [];
    this.size = 0;
    if (this.x < 0 || this.y < 0 || this.width < 1 || this.height < 1) {
      throw new Error("Dimensions and coordinates must be positive integers.");
    }
    if (this.maxElements < 1) {
      throw new Error("The maximum number of elements before a split must be a positive integer.");
    }
    that = this;
    this.children = {
      "NW": {
        create: function() {
          return new Quadtree({
            x: that.x,
            y: that.y,
            width: Math.max(Math.floor(that.width / 2), 1),
            height: Math.max(Math.floor(that.height / 2), 1),
            maxElements: that.maxElements
          });
        },
        tree: null
      },
      "NE": {
        create: function() {
          return new Quadtree({
            x: that.x + Math.max(Math.floor(that.width / 2), 1),
            y: that.y,
            width: Math.ceil(that.width / 2),
            height: Math.max(Math.floor(that.height / 2), 1),
            maxElements: that.maxElements
          });
        },
        tree: null
      },
      "SW": {
        create: function() {
          return new Quadtree({
            x: that.x,
            y: that.y + Math.max(Math.floor(that.height / 2), 1),
            width: Math.max(Math.floor(that.width / 2), 1),
            height: Math.ceil(that.height / 2),
            maxElements: that.maxElements
          });
        },
        tree: null
      },
      "SE": {
        create: function() {
          return new Quadtree({
            x: that.x + Math.max(Math.floor(that.width / 2), 1),
            y: that.y + Math.max(Math.floor(that.height / 2), 1),
            width: Math.ceil(that.width / 2),
            height: Math.ceil(that.height / 2),
            maxElements: that.maxElements
          });
        },
        tree: null
      }
    };
    for (child in this.children) {
      this.children[child].get = function() {
        if (this.tree != null) {
          return this.tree;
        } else {
          this.tree = this.create();
          return this.tree;
        }
      };
    }
  }

  getCenter = function(item) {
    var ref, ref1;
    return {
      x: Math.floor(((ref = item.width) != null ? ref : 1) / 2) + item.x,
      y: Math.floor(((ref1 = item.height) != null ? ref1 : 1) / 2) + item.y
    };
  };

  validateElement = function(element) {
    if (!typeof element === "object" || (element.x == null) || (element.y == null) || element.x < 0 || element.y < 0) {
      throw new Error("Object must contain x or y positions as arguments, and they must be positive integers.");
    }
    if ((element != null ? element.width : void 0) < 0 || (element != null ? element.height : void 0) < 0) {
      throw new Error("Width and height must be positive integers.");
    }
  };

  calculateDirection = function(element, tree) {
    var quadCenter;
    quadCenter = getCenter(tree);
    if (element.x < quadCenter.x) {
      if (element.y < quadCenter.y) {
        return "NW";
      } else {
        return "SW";
      }
    } else {
      if (element.y < quadCenter.y) {
        return "NE";
      } else {
        return "SE";
      }
    }
  };

  isOversized = function(element, tree) {
    var ref, ref1;
    return element.x < tree.x || element.x + ((ref = element.width) != null ? ref : 0) >= tree.x + tree.width || element.y < tree.y || element.y + ((ref1 = element.height) != null ? ref1 : 0) >= tree.y + tree.height;
  };

  observe = function(item, tree) {
    var writeAccessors;
    writeAccessors = function(propName) {
      item["_" + propName] = item[propName];
      return Object.defineProperty(item, propName, {
        set: function(val) {
          tree.remove(this);
          this["_" + propName] = val;
          return tree.push(this);
        },
        get: function() {
          return this["_" + propName];
        },
        configurable: true
      });
    };
    writeAccessors("x");
    writeAccessors("y");
    writeAccessors("width");
    return writeAccessors("height");
  };

  Quadtree.prototype.push = function(item, doObserve) {
    return this.pushAll([item], doObserve);
  };

  Quadtree.prototype.pushAll = function(items, doObserve) {
    var candidate, content, contentDir, direction, element, elements, fifo, fifoCandidates, item, j, k, l, len, len1, len2, ref, relatedChild, top, tree;
    for (j = 0, len = items.length; j < len; j++) {
      item = items[j];
      validateElement(item);
      if (doObserve) {
        observe(item, this);
      }
    }
    fifo = [
      {
        tree: this,
        elements: items
      }
    ];
    while (fifo.length > 0) {
      top = fifo.shift();
      tree = top.tree;
      elements = top.elements;
      fifoCandidates = {
        "NW": null,
        "NE": null,
        "SW": null,
        "SE": null
      };
      for (k = 0, len1 = elements.length; k < len1; k++) {
        element = elements[k];
        tree.size++;
        direction = calculateDirection(element, tree);
        relatedChild = tree.children[direction];
        if (tree.width === 1 || tree.height === 1 || isOversized(element, relatedChild.create())) {
          tree.oversized.push(element);
        } else if (tree.size <= tree.maxElements) {
          tree.contents.push(element);
        } else {
          if (fifoCandidates[direction] == null) {
            fifoCandidates[direction] = {
              tree: relatedChild.get(),
              elements: []
            };
          }
          fifoCandidates[direction].elements.push(element);
          ref = tree.contents;
          for (l = 0, len2 = ref.length; l < len2; l++) {
            content = ref[l];
            contentDir = calculateDirection(content, tree);
            if (fifoCandidates[contentDir] == null) {
              fifoCandidates[contentDir] = {
                tree: tree.children[contentDir].get(),
                elements: []
              };
            }
            fifoCandidates[contentDir].elements.push(content);
          }
          tree.contents = [];
        }
      }
      for (direction in fifoCandidates) {
        candidate = fifoCandidates[direction];
        if (candidate != null) {
          fifo.push(candidate);
        }
      }
    }
    return this;
  };

  Quadtree.prototype.remove = function(item) {
    var index, relatedChild;
    validateElement(item);
    index = this.oversized.indexOf(item);
    if (index > -1) {
      this.oversized.splice(index, 1);
      this.size--;
      return true;
    }
    index = this.contents.indexOf(item);
    if (index > -1) {
      this.oversized.splice(index, 1);
      this.size--;
      return true;
    }
    relatedChild = this.children[calculateDirection(item, this)];
    if (relatedChild.tree == null) {
      return false;
    }
    if (relatedChild.tree.remove(item)) {
      this.size--;
      if (relatedChild.tree.size === 0) {
        relatedChild.tree = null;
      }
      return true;
    } else {
      return false;
    }
  };

  Quadtree.prototype.colliding = function(item, collisionFunction) {
    var boundingBoxCollision, child, elt, fifo, items, j, k, len, len1, ref, ref1, relatedChild, top;
    validateElement(item);
    boundingBoxCollision = function(elt1, elt2) {
      var ref, ref1, ref2, ref3;
      return !(elt1.x > elt2.x + ((ref = elt2.width) != null ? ref : 0) || elt1.x + ((ref1 = elt1.width) != null ? ref1 : 0) < elt2.x || elt1.y > elt2.y + ((ref2 = elt2.height) != null ? ref2 : 0) || elt1.y + ((ref3 = elt1.height) != null ? ref3 : 0) < elt2.y);
    };
    if (collisionFunction == null) {
      collisionFunction = boundingBoxCollision;
    }
    items = [];
    fifo = [this];
    while (fifo.length > 0) {
      top = fifo.shift();
      ref = top.oversized;
      for (j = 0, len = ref.length; j < len; j++) {
        elt = ref[j];
        if (elt !== item && collisionFunction(item, elt)) {
          items.push(elt);
        }
      }
      ref1 = top.contents;
      for (k = 0, len1 = ref1.length; k < len1; k++) {
        elt = ref1[k];
        if (elt !== item && collisionFunction(item, elt)) {
          items.push(elt);
        }
      }
      relatedChild = top.children[calculateDirection(item, top)];
      if (isOversized(item, relatedChild.create())) {
        for (child in top.children) {
          if ((top.children[child].tree != null) && boundingBoxCollision(top.children[child].tree, item)) {
            fifo.push(top.children[child].tree);
          }
        }
      } else if (relatedChild.tree != null) {
        fifo.push(relatedChild.tree);
      }
    }
    return items;
  };

  Quadtree.prototype.get = function(query) {
    return this.where(query);
  };

  Quadtree.prototype.where = function(query) {
    var check, elt, fifo, items, j, k, key, len, len1, ref, ref1, relatedChild, top;
    if (typeof query === "object" && (query.x == null) && (query.y == null)) {
      return this.find(function(elt) {
        var check, key;
        check = true;
        for (key in query) {
          if (query[key] !== elt[key]) {
            check = false;
          }
        }
        return check;
      });
    }
    validateElement(query);
    items = [];
    fifo = [this];
    while (fifo.length > 0) {
      top = fifo.shift();
      ref = top.oversized;
      for (j = 0, len = ref.length; j < len; j++) {
        elt = ref[j];
        check = true;
        for (key in query) {
          if (query[key] !== elt[key]) {
            check = false;
          }
        }
        if (check) {
          items.push(elt);
        }
      }
      ref1 = top.contents;
      for (k = 0, len1 = ref1.length; k < len1; k++) {
        elt = ref1[k];
        check = true;
        for (key in query) {
          if (query[key] !== elt[key]) {
            check = false;
          }
        }
        if (check) {
          items.push(elt);
        }
      }
      relatedChild = top.children[calculateDirection(query, top)];
      if (relatedChild.tree != null) {
        fifo.push(relatedChild.tree);
      }
    }
    return items;
  };

  Quadtree.prototype.each = function(action) {
    var child, fifo, i, j, k, len, len1, ref, ref1, top;
    fifo = [this];
    while (fifo.length > 0) {
      top = fifo.shift();
      ref = top.oversized;
      for (j = 0, len = ref.length; j < len; j++) {
        i = ref[j];
        if (typeof action === "function") {
          action(i);
        }
      }
      ref1 = top.contents;
      for (k = 0, len1 = ref1.length; k < len1; k++) {
        i = ref1[k];
        if (typeof action === "function") {
          action(i);
        }
      }
      for (child in top.children) {
        if (top.children[child].tree != null) {
          fifo.push(top.children[child].tree);
        }
      }
    }
    return this;
  };

  Quadtree.prototype.find = function(predicate) {
    var child, fifo, i, items, j, k, len, len1, ref, ref1, top;
    fifo = [this];
    items = [];
    while (fifo.length > 0) {
      top = fifo.shift();
      ref = top.oversized;
      for (j = 0, len = ref.length; j < len; j++) {
        i = ref[j];
        if (typeof predicate === "function" ? predicate(i) : void 0) {
          items.push(i);
        }
      }
      ref1 = top.contents;
      for (k = 0, len1 = ref1.length; k < len1; k++) {
        i = ref1[k];
        if (typeof predicate === "function" ? predicate(i) : void 0) {
          items.push(i);
        }
      }
      for (child in top.children) {
        if (top.children[child].tree != null) {
          fifo.push(top.children[child].tree);
        }
      }
    }
    return items;
  };

  Quadtree.prototype.filter = function(predicate) {
    var deepclone;
    deepclone = function(target) {
      var child, copycat, item, j, k, len, len1, ref, ref1, ref2, ref3;
      copycat = new Quadtree({
        x: target.x,
        y: target.y,
        width: target.width,
        height: target.height,
        maxElements: target.maxElements
      });
      copycat.size = 0;
      for (child in target.children) {
        if (!(target.children[child].tree != null)) {
          continue;
        }
        copycat.children[child].tree = deepclone(target.children[child].tree);
        copycat.size += (ref = (ref1 = copycat.children[child].tree) != null ? ref1.size : void 0) != null ? ref : 0;
      }
      ref2 = target.oversized;
      for (j = 0, len = ref2.length; j < len; j++) {
        item = ref2[j];
        if ((predicate == null) || (typeof predicate === "function" ? predicate(item) : void 0)) {
          copycat.oversized.push(item);
        }
      }
      ref3 = target.contents;
      for (k = 0, len1 = ref3.length; k < len1; k++) {
        item = ref3[k];
        if ((predicate == null) || (typeof predicate === "function" ? predicate(item) : void 0)) {
          copycat.contents.push(item);
        }
      }
      copycat.size += copycat.oversized.length + copycat.contents.length;
      if (copycat.size === 0) {
        return null;
      } else {
        return copycat;
      }
    };
    return deepclone(this);
  };

  Quadtree.prototype.reject = function(predicate) {
    return this.filter(function(i) {
      return !(typeof predicate === "function" ? predicate(i) : void 0);
    });
  };

  Quadtree.prototype.visit = function(action) {
    var child, fifo, that;
    fifo = [this];
    while (fifo.length > 0) {
      that = fifo.shift();
      action.bind(that)();
      for (child in that.children) {
        if (that.children[child].tree != null) {
          fifo.push(that.children[child].tree);
        }
      }
    }
    return this;
  };

  Quadtree.prototype.pretty = function() {
    var child, fifo, indent, indentation, isParent, str, top;
    str = "";
    indent = function(level) {
      var j, ref, res, times;
      res = "";
      for (times = j = ref = level; ref <= 0 ? j < 0 : j > 0; times = ref <= 0 ? ++j : --j) {
        res += "   ";
      }
      return res;
    };
    fifo = [
      {
        label: "ROOT",
        tree: this,
        level: 0
      }
    ];
    while (fifo.length > 0) {
      top = fifo.shift();
      indentation = indent(top.level);
      str += indentation + "| " + top.label + "\n" + indentation + "| ------------\n";
      if (top.tree.oversized.length > 0) {
        str += indentation + "| * Oversized elements *\n" + indentation + "|   " + top.tree.oversized + "\n";
      }
      if (top.tree.contents.length > 0) {
        str += indentation + "| * Leaf content *\n" + indentation + "|   " + top.tree.contents + "\n";
      }
      isParent = false;
      for (child in top.tree.children) {
        if (!(top.tree.children[child].tree != null)) {
          continue;
        }
        isParent = true;
        fifo.unshift({
          label: child,
          tree: top.tree.children[child].tree,
          level: top.level + 1
        });
      }
      if (isParent) {
        str += indentation + "└──┐\n";
      }
    }
    return str;
  };

  return Quadtree;

})();

if (typeof module !== "undefined" && module !== null) {
  module.exports = Quadtree;
}
