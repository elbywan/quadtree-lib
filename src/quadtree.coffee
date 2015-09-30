class Quadtree
    constructor: ({@x, @y, @width, @height}) ->
        throw new Error "Missing quadtree dimensions." if not @width? or not @height?
        throw new Error "Dimensions must be positive integers." if @x < 0 or @y < 0 or @width < 1 or @height < 1
        @x ?= 0
        @y ?= 0
        @contents = []
        @oversized = []
        @size = 0

        that = @

        @children = {
            "NW":
                create: () ->
                    new Quadtree({
                        x: that.x
                        y: that.y
                        width: Math.max (Math.floor that.width / 2), 1
                        height: Math.max (Math.floor that.height / 2), 1
                    })
                tree: null
            "NE":
                create: () ->
                    new Quadtree({
                        x: that.x + Math.max (Math.floor that.width / 2), 1
                        y: that.y
                        width: Math.ceil that.width / 2
                        height: Math.max (Math.floor that.height / 2), 1
                    })
                tree: null
            "SW":
                create: () ->
                    new Quadtree({
                        x: that.x
                        y: that.y + Math.min (Math.floor that.height / 2), 1
                        width: Math.min (Math.floor that.width / 2), 1
                        height: Math.ceil that.height / 2
                    })
                tree: null
            "SE":
                create: () ->
                    new Quadtree({
                        x: that.x + Math.max (Math.floor that.width / 2), 1
                        y: that.y + Math.max (Math.floor that.height / 2), 1
                        width: Math.ceil that.width / 2
                        height: Math.ceil that.height / 2
                    })
                tree: null
        }
        for child of @children
            @children[child].get = () ->
                if @tree? then @tree else @tree = @create(); @tree

    ## Internal methods & vars ##

    getCenter = (item) ->
        x: Math.floor((item.width  ? 1) / 2) + item.x
        y: Math.floor((item.height ? 1) / 2) + item.y

    validateElement = (element) ->
        if not typeof element is "object" or not element.x? or not element.y? or element.x < 0 or element.y < 0
            throw new Error "Object must contain x or y positions as arguments, and they must be positive integers."
        if element?.width < 1 or element?.height < 1
            throw new Error "Width and height arguments must be greater than 0."

    calculateDirection = (element, tree) ->
        element
        quadCenter = getCenter tree

        if element.x < quadCenter.x
            if element.y < quadCenter.y then "NW"
            else "SW"
        else
            if element.y < quadCenter.y then "NE"
            else "SE"

    isOversized = (element, tree) ->
        element.x < tree.x or
        element.x + (element.width ? 1) >= tree.x + tree.width or
        element.y < tree.y or
        element.y + (element.height ? 1) >= tree.y + tree.height

    ## Exposed methods ##

    push: (item) ->
        validateElement item

        fifo = [tree: @, element: item]

        while fifo.length > 0
            top = fifo.splice(0, 1)[0]
            tree = top.tree
            element = top.element

            tree.size++

            relatedChild = tree.children[calculateDirection element, tree]

            if tree.width is 1 or tree.height is 1 or isOversized element, relatedChild.create()
                tree.oversized.push element

            else if tree.size is 1
                tree.contents.push element


            else
                fifo.push tree: relatedChild.get(), element: element

                for c in tree.contents
                    fifo.push tree: tree.children[calculateDirection c, tree].get(), element: c

                tree.contents = []
        @

    remove: (item) ->
        validateElement item

        index = @oversized.indexOf item
        if index > - 1
            @oversized.splice index, 1
            @size--
            return true
        index = @contents.indexOf item
        if index > - 1
            @oversized.splice index, 1
            @size--
            return true

        relatedChild = @children[calculateDirection item, @]
        if not relatedChild.tree?
            return false

        if relatedChild.tree.remove item
            @size--
            relatedChild.tree = null if relatedChild.tree.size is 0
            true
        else
            false

    colliding: (item, collisionFunction) ->
        validateElement item

        # Default rectangle collision
        if not collisionFunction?
            collisionFunction = (elt1, elt2) ->
                not(elt1.x > elt2.x + (elt2.width ? 1)      or
                    elt1.x + (elt1.width ? 1) < elt2.x      or
                    elt1.y > elt2.y + (elt2.height ? 1)     or
                    elt1.y + (elt1.height ? 1) < elt2.y)

        items = []
        fifo = [@]

        while fifo.length > 0
            top = fifo.splice(0, 1)[0]

            for elt in top.oversized then if elt isnt item and collisionFunction item, elt then items.push elt
            for elt in top.contents  then if elt isnt item and collisionFunction item, elt then items.push elt

            relatedChild = top.children[calculateDirection item, @]

            if isOversized item, relatedChild.create()
                for child of top.children when top.children[child].tree?
                    fifo.push top.children[child].tree

            else if relatedChild.tree?
                fifo.push relatedChild.tree

        items

    each: (action) ->
        fifo = [@]

        while fifo.length > 0
            top = fifo.splice(0, 1)[0]
            for i in top.oversized then action?(i)
            for i in top.contents then action?(i)

            for child of top.children when top.children[child].tree?
                fifo.push top.children[child].tree
        @

    filter: (validate) ->
        deepclone = (target) ->
            copycat = new Quadtree x: target.x, y: target.y, width: target.width, height: target.height
            copycat.size = 0
            for child of target.children when target.children[child].tree?
                copycat.children[child].tree = deepclone target.children[child].tree
                copycat.size += copycat.children[child].tree?.size ? 0

            for item in target.oversized when not validate? or validate?(item)
                copycat.oversized.push item
            for item in target.contents when not validate? or validate?(item)
                copycat.contents.push item

            copycat.size += copycat.oversized.length + copycat.contents.length
            if copycat.size is 0 then null else copycat

        deepclone @

    visit: (action) ->
        fifo = [@]

        while fifo.length > 0
            that = fifo.splice(0, 1)[0]
            action.bind(that)()

            for child of that.children when that.children[child].tree?
                fifo.push that.children[child].tree
        @

module?.exports = Quadtree
