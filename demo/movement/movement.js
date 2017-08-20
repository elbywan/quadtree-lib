/* global window, document */

window.demo = (function() {

    var canvas = document.getElementById("quadtree_canvas")
    var ctx = canvas.getContext("2d")
    var container = document.getElementById("canvas-container")
    var counter = document.getElementById("counter")
    var width = Math.min(container.clientWidth, window.innerWidth)
    var height = width === window.innerWidth ? window.innerWidth : container.clientHeight

    var movementDemo = {

        quadtreeColor: "rgba(120, 144, 156, 0.1)",
        eltColor: "rgba(136, 14, 79, 1)",
        eltNb: 50,
        elts: [],
        quadtree: null,

        init: function() {
            canvas.width = width
            canvas.height = height
            container.style.height = height + "px"
            ctx.clearRect(0, 0, width, height)
            ctx.lineWidth = 1
            this.quadtree = new window.Quadtree({
                width: width,
                height: height
            })
            this.elts = []
            for(var i = 0; i < this.eltNb; i++) {
                this.elts.push(this.randomElement())
            }
            this.quadtree.pushAll(this.elts)
            this.updateCanvas()
            this.updateCounter()
        },

        randomElement: function() {
            var squareWidth = window.randomNb(5, 20)

            return {
                x: window.randomNb(0, width - squareWidth),
                y: window.randomNb(0, height - squareWidth),
                width: squareWidth,
                height: squareWidth,
                speed: window.randomNb(1, 5),
                direction: [ window.randomNb(-1, 2) || -1, window.randomNb(-1, 2) || 1 ],
                delay: window.randomNb(1, 3),
                delayIncrement: 0,
                color: this.eltColor
            }
        },

        addElements: function() {
            var elementArray = []
            for(var i = 0; i < this.eltNb; i++) {
                var elt = this.randomElement()
                elementArray.push(elt)
                this.elts.push(elt)
            }
            this.quadtree.pushAll(elementArray)
            this.updateCounter()
        },

        updateCanvas: function() {
            ctx.clearRect(0, 0, width, height)
            var that = this
            this.quadtree.visit(function() {
                ctx.strokeStyle = that.quadtreeColor
                window.drawQuadtree(this, false, ctx)
                for(var i in this.contents) {
                    ctx.fillStyle = this.contents[i].color
                    window.drawSquare(this.contents[i], true, ctx)
                }
                for(var j in this.oversized) {
                    ctx.fillStyle = this.oversized[j].color
                    window.drawSquare(this.oversized[j], true, ctx)
                }
            })
        },

        updateCounter: function() {
            counter.innerHTML = this.quadtree.size + " elements"
        },

        movementTick: function() {
            var that = this
            this.elts.forEach(function(elt) {
                var collisions = that.quadtree.colliding(elt)
                if(elt.x < 0) {
                    if(elt.direction[0] < 0)
                        elt.direction[0] = -elt.direction[0]
                    elt.x = 0
                } else if(elt.x + elt.width > width) {
                    if(elt.direction[0] > 0)
                        elt.direction[0] = -elt.direction[0]
                    elt.x = width - elt.width
                } else if(elt.y < 0) {
                    if(elt.direction[1] < 0)
                        elt.direction[1] = -elt.direction[1]
                    elt.y = 0
                } else if(elt.y + elt.height > height) {
                    if(elt.direction[1] > 0)
                        elt.direction[1] = -elt.direction[1]
                    elt.y = height - elt.height
                } else if(collisions.length > 0) {
                    elt.color = window.randomColor()
                    var collision = collisions[0]
                    var edges = {}
                    if(collision.x <= elt.x && collision.x + collision.width  >= elt.x)  {
                        edges.left = collision.x + collision.width - elt.x
                    }
                    if(collision.x + collision.width >= elt.x + elt.width && collision.x <= elt.x + elt.width) {
                        edges.right = elt.x + elt.width - collision.x
                    }
                    if(collision.y <= elt.y && collision.y + collision.height  >= elt.y)  {
                        edges.top = collision.y + collision.height - elt.y
                    }
                    if(collision.y + collision.height >= elt.y + elt.height && collision.y <= elt.y + elt.height) {
                        edges.bottom = elt.y + elt.height - collision.y
                    }
                    var bestEdge = null
                    for(var key in edges) {
                        if(!bestEdge || bestEdge[1] > edges[key])
                            bestEdge = [ key, edges[key] ]
                    }
                    if(bestEdge) {
                        if(bestEdge[0] === "top") {
                            if(elt.direction[1] < 0)
                                elt.direction[1] = -elt.direction[1]
                            // elt.y = collision.y + collision.height
                        } else if(bestEdge[0] === "bottom") {
                            if(elt.direction[1] > 0)
                                elt.direction[1] = -elt.direction[1]
                            // elt.y = collision.y - elt.height
                        } else if(bestEdge[0] === "left") {
                            if(elt.direction[0] < 0)
                                elt.direction[0] = -elt.direction[0]
                            // elt.x = collision.x + collision.width
                        } else if(bestEdge[0] === "right") {
                            if(elt.direction[0] > 0)
                                elt.direction[0] = -elt.direction[0]
                            // elt.x = collision.x - elt.width
                        }
                    }
                }
            })
            var removedElts = []
            this.elts.forEach(function(elt) {
                elt.delayIncrement = (elt.delayIncrement + 1) % elt.delay
                if(elt.delayIncrement === 0) {
                    that.quadtree.remove(elt)
                    removedElts.push(elt)
                    elt.x += elt.direction[0] * elt.speed
                    elt.y += elt.direction[1] * elt.speed
                }
            })
            this.quadtree.pushAll(removedElts)
        }
    }

    document.addEventListener("DOMContentLoaded", function() {
        movementDemo.init()
    })

    var renderingLoop = function() {
        movementDemo.movementTick()
        movementDemo.updateCanvas()
        window.requestAnimationFrame(renderingLoop)
    }

    window.requestAnimationFrame(renderingLoop)

    return movementDemo
}())
