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
    var resizeAction = function(event) {
        var targetRect = element.getBoundingClientRect()
        if(boundaryElement) {
            var boundaries = boundaryElement.getBoundingClientRect()
            element.style.height = Math.max(5, Math.min(event.clientY - targetRect.top,  boundaries.bottom - targetRect.top))
            element.style.width  = Math.max(5, Math.min(event.clientX - targetRect.left, boundaries.right  - targetRect.left))
        } else {
            element.style.height = Math.max(5, event.clientY - targetRect.top)
            element.style.width  = Math.max(5, event.clientX - targetRect.left)
        }

        if(callbacks && callbacks.onResize && typeof callbacks.onResize === "function") {
            callbacks.onResize()
        }
    }
    var lastMovePos = null
    var moveAction = function(event) {
        if(boundaryElement && boundaryElement.contains(event.target)) {
            var boundaries = boundaryElement.getBoundingClientRect()

            element.style.top  = parseInt(getComputedStyle(element).top)  + event.clientY - lastMovePos.y
            element.style.left = parseInt(getComputedStyle(element).left) + event.clientX - lastMovePos.x
            element.style.top  = Math.max(0, Math.min(parseInt(element.style.top),  boundaries.height - parseInt(getComputedStyle(element).height)))
            element.style.left = Math.max(0, Math.min(parseInt(element.style.left), boundaries.width  - parseInt(getComputedStyle(element).width)))

            lastMovePos = {x: event.clientX, y: event.clientY}

            if(callbacks && callbacks.onMove && typeof callbacks.onMove === "function") {
                callbacks.onMove()
            }
        } else if(!boundaryElement) {
            element.style.top  = parseInt(getComputedStyle(element).top)  + event.clientY - lastMovePos.y
            element.style.left = parseInt(getComputedStyle(element).left) + event.clientX - lastMovePos.x

            lastMovePos = {x: event.clientX, y: event.clientY}

            if(callbacks && callbacks.onMove && typeof callbacks.onMove === "function") {
                callbacks.onMove()
            }
        }
    }

    element.addEventListener('mousedown', function(event) {
        var targetRect = element.getBoundingClientRect()
        if(Math.abs(event.clientY - targetRect.bottom) < 12 && Math.abs(event.clientX - targetRect.right < 12))
            document.getElementsByTagName('body')[0].addEventListener('mousemove', resizeAction)
        else {
            document.getElementsByTagName('body')[0].addEventListener('mousemove', moveAction)
            lastMovePos = {x: event.clientX, y: event.clientY}
        }
    })

    document.getElementsByTagName('body')[0].addEventListener('mouseup', function(event) {
        document.getElementsByTagName('body')[0].removeEventListener('mousemove', resizeAction)
        document.getElementsByTagName('body')[0].removeEventListener('mousemove', moveAction)
    })
}
