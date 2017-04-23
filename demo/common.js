var randomNb = function(min, max){
    if(min >= max)
        throw new Error('min must be < max')
    return Math.floor(Math.random() * (max - min)) + min
}

var drawSquare = function(elt, fill, context){
    if(!context)
        context = ctx
    context.beginPath()
    context.moveTo(elt.x, elt.y)
    context.lineTo(elt.x + (elt.width ? elt.width : 1), elt.y)
    context.lineTo(elt.x + (elt.width ? elt.width : 1), elt.y + (elt.height ? elt.height : 1))
    context.lineTo(elt.x, elt.y + (elt.height ? elt.height : 1))
    context.closePath()
    context.stroke()
    if(fill)
        context.fill()
}

var drawQuadtree = function(tree, fill, context) {
    var halfWidth  = Math.max(Math.floor(tree.width  / 2), 1)
    var halfHeight = Math.max(Math.floor(tree.height / 2), 1)

    drawSquare({
        x: tree.x,
        y: tree.y,
        width:  halfWidth,
        height: halfHeight
    }, fill, context)
    drawSquare({
        x: tree.x + halfWidth,
        y: tree.y,
        width:  halfWidth,
        height: halfHeight
    }, fill, context)
    drawSquare({
        x: tree.x,
        y: tree.y + halfHeight,
        width:  halfWidth,
        height: halfHeight
    }, fill, context)
    drawSquare({
        x: tree.x + halfWidth,
        y: tree.y + halfHeight,
        width:  halfWidth,
        height: halfHeight
    }, fill, context)
}

var makeMovable = function(element, boundaryElement, callbacks) {
    var extractPos = function(event) {
        return {
            x: event.clientX ? event.clientX : event.changedTouches[0].clientX,
            y: event.clientY ? event.clientY : event.changedTouches[0].clientY
        }
    }

    var resizeAction = function(event) {
        var targetRect = element.getBoundingClientRect()
        var position = extractPos(event)

        if(boundaryElement) {
            var boundaries = boundaryElement.getBoundingClientRect()
            element.style.height = Math.max(5, Math.min(position.y - targetRect.top,  boundaries.bottom - targetRect.top))
            element.style.width  = Math.max(5, Math.min(position.x - targetRect.left, boundaries.right  - targetRect.left))
        } else {
            element.style.height = Math.max(5, position.y - targetRect.top)
            element.style.width  = Math.max(5, position.x - targetRect.left)
        }

        if(callbacks && callbacks.onResize && typeof callbacks.onResize === "function") {
            callbacks.onResize()
        }
    }
    var lastMovePos = null
    var clickAction = function(event) {
        var targetRect = element.getBoundingClientRect()
        var position = extractPos(event)

        if(Math.abs(position.y - targetRect.bottom) < 12 && Math.abs(position.x - targetRect.right < 12)) {
            document.getElementsByTagName('body')[0].addEventListener('mousemove', resizeAction)
            document.getElementsByTagName('body')[0].addEventListener('touchmove', resizeAction)
        } else {
            document.getElementsByTagName('body')[0].addEventListener('mousemove', moveAction)
            document.getElementsByTagName('body')[0].addEventListener('touchmove', moveAction)
            lastMovePos = {x: position.x, y: position.y}
        }
        event.preventDefault()
    }
    var moveAction = function(event) {
        var position = extractPos(event)

        if(boundaryElement && boundaryElement.contains(event.target)) {
            var boundaries = boundaryElement.getBoundingClientRect()

            element.style.top  = parseInt(getComputedStyle(element).top)  + position.y - lastMovePos.y
            element.style.left = parseInt(getComputedStyle(element).left) + position.x - lastMovePos.x
            element.style.top  = Math.max(0, Math.min(parseInt(element.style.top),  boundaries.height - parseInt(getComputedStyle(element).height)))
            element.style.left = Math.max(0, Math.min(parseInt(element.style.left), boundaries.width  - parseInt(getComputedStyle(element).width)))

            lastMovePos = {x: position.x, y: position.y}

            if(callbacks && callbacks.onMove && typeof callbacks.onMove === "function") {
                callbacks.onMove()
            }
        } else if(!boundaryElement) {
            element.style.top  = parseInt(getComputedStyle(element).top)  + position.y - lastMovePos.y
            element.style.left = parseInt(getComputedStyle(element).left) + position.x - lastMovePos.x

            lastMovePos = {x: position.x, y: position.y}

            if(callbacks && callbacks.onMove && typeof callbacks.onMove === "function") {
                callbacks.onMove()
            }
        }
    }

    element.addEventListener('mousedown',  clickAction)
    element.addEventListener('touchstart', clickAction)

    document.getElementsByTagName('body')[0].addEventListener('mouseup', function(event) {
        document.getElementsByTagName('body')[0].removeEventListener('mousemove', resizeAction)
        document.getElementsByTagName('body')[0].removeEventListener('mousemove', moveAction)
    })
    document.getElementsByTagName('body')[0].addEventListener('touchend', function(event) {
        document.getElementsByTagName('body')[0].removeEventListener('touchmove', resizeAction)
        document.getElementsByTagName('body')[0].removeEventListener('touchmove', moveAction)
    })

}
