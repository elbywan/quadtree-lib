/* global window, document */

window.demo = (function() {

    var canvas = document.getElementById("quadtree_canvas")
    var ctx = canvas.getContext("2d")
    var layer = document.getElementById("layer_canvas")
    var layerCtx = layer.getContext("2d")
    var container = document.getElementById("canvas-container")
    var collisitionRect = document.getElementById("canvas-collision")
    var counter = document.getElementById("counter")
    var width = Math.min(container.clientWidth, window.innerWidth)
    var height = width === window.innerWidth ? window.innerWidth : container.clientHeight

    var collisionsDemo = {

        quadtreeColor: "rgba(120, 144, 156, 0.1)",
        scannedColor: "rgba(229, 57, 53, 1)",
        eltColor: "rgba(136, 14, 79, 1)",
        collidingColor: "#F57F17",
        eltNb: 1000,
        eltIncrement: 100,
        quadtree: null,

        init: function() {
            canvas.width = width
            canvas.height = height
            container.style.height = height + "px"
            ctx.clearRect(0, 0, width, height)
            ctx.lineWidth = 1
            layer.width = width
            layer.height = height
            layerCtx.clearRect(0, 0, width, height)
            layerCtx.lineWidth = 1
            this.quadtree = new window.Quadtree({
                width: width,
                height: height
            })
            var elts = []
            for(var i = 0; i < this.eltNb; i++) {
                elts.push(this.randomizeElement())
            }
            this.quadtree.pushAll(elts)
            this.updateCanvas()
            this.updateLayer()
        },
        updateCanvas: function() {
            ctx.clearRect(0, 0, width, height)
            var that = this
            this.quadtree.visit(function() {
                ctx.strokeStyle = that.quadtreeColor
                window.drawQuadtree(this, false, ctx)
                ctx.fillStyle = that.eltColor
                for(var i in this.contents)
                    window.drawSquare(this.contents[i], true, ctx)
                for(var j in this.oversized)
                    window.drawSquare(this.oversized[j], true, ctx)
            })
        },
        updateLayer: function() {
            var scanned = 0
            var colliding = 0
            var total = this.quadtree.size
            var that = this

            var monkeyPatchCollisionAlgorithm = function(elt1, elt2) {
                layerCtx.fillStyle = that.scannedColor
                window.drawSquare(elt2, true, layerCtx)
                scanned++
                var ref, ref1, ref2, ref3
                return !(elt1.x > elt2.x + ((ref = elt2.width) != null ? ref : 0) || elt1.x + ((ref1 = elt1.width) != null ? ref1 : 0) < elt2.x || elt1.y > elt2.y + ((ref2 = elt2.height) != null ? ref2 : 0) || elt1.y + ((ref3 = elt1.height) != null ? ref3 : 0) < elt2.y)
            }

            layerCtx.clearRect(0, 0, width, height)
            var containerBox = container.getBoundingClientRect()
            var collisionBox = collisitionRect.getBoundingClientRect()
            var coordinates = {
                x: collisionBox.left - containerBox.left,
                y: collisionBox.top - containerBox.top,
                width: collisionBox.width,
                height: collisionBox.height
            }

            this.quadtree.colliding(coordinates, monkeyPatchCollisionAlgorithm).forEach(function(elt) {
                layerCtx.fillStyle = that.collidingColor
                window.drawSquare(elt, true, layerCtx)
                colliding++
            })

            this.updateCounters(scanned, colliding, total)
        },
        randomizeElement: function() {
            var squareSize = window.randomNb(5, 15)
            return {
                x: window.randomNb(0, width),
                y: window.randomNb(0, height),
                width: squareSize,
                height: squareSize,
                color: this.eltColor
            }
        },
        updateCounters: function(scanned, colliding, total) {
            counter.innerHTML = "Total : " + total + " | Scanned : " + scanned + " | Colliding : " + colliding
        },
        addElements: function() {
            var elementArray = []
            for(var i = 0; i < this.eltIncrement; i++)
                elementArray.push(this.randomizeElement())
            this.quadtree.pushAll(elementArray)
            this.updateCanvas()
            this.updateLayer()
        }

    }

    document.addEventListener("DOMContentLoaded", function() {
        collisionsDemo.init()
        window.makeMovable(collisitionRect, container, {
            onMove: function() {
                collisionsDemo.updateLayer()
            },
            onResize: function() {
                collisionsDemo.updateLayer()
            }
        })
    })

    return collisionsDemo

}())
