class Quadtree
    constructor: ({@x, @y, @width, @height, @maxElements}) ->
        throw new Error "Missing quadtree dimensions." if not @width? or not @height?
        @x ?= 0
        @y ?= 0
        @maxElements ?= 1
        @contents = []
        @oversized = []
        @size = 0

        throw new Error "Dimensions must be positive integers." if @x < 0 or @y < 0 or @width < 1 or @height < 1
        throw new Error "The maximum of elements by leaf must be a positive integer." if @maxElements < 1

        that = @

        @children = {
            "NW":
                create: () ->
                    new Quadtree({
                        x: that.x
                        y: that.y
                        width: Math.max (Math.floor that.width / 2), 1
                        height: Math.max (Math.floor that.height / 2), 1
                        maxElements: that.maxElements
                    })
                tree: null
            "NE":
                create: () ->
                    new Quadtree({
                        x: that.x + Math.max (Math.floor that.width / 2), 1
                        y: that.y
                        width: Math.ceil that.width / 2
                        height: Math.max (Math.floor that.height / 2), 1
                        maxElements: that.maxElements
                    })
                tree: null
            "SW":
                create: () ->
                    new Quadtree({
                        x: that.x
                        y: that.y + Math.max (Math.floor that.height / 2), 1
                        width: Math.max (Math.floor that.width / 2), 1
                        height: Math.ceil that.height / 2
                        maxElements: that.maxElements
                    })
                tree: null
            "SE":
                create: () ->
                    new Quadtree({
                        x: that.x + Math.max (Math.floor that.width / 2), 1
                        y: that.y + Math.max (Math.floor that.height / 2), 1
                        width: Math.ceil that.width / 2
                        height: Math.ceil that.height / 2
                        maxElements: that.maxElements
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
        if element?.width < 0 or element?.height < 0
            throw new Error "Width and height arguments must be positive integers."

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
        element.x + (element.width ? 0) >= tree.x + tree.width or
        element.y < tree.y or
        element.y + (element.height ? 0) >= tree.y + tree.height

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

            else if tree.size <= tree.maxElements
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
                not(elt1.x > elt2.x + (elt2.width ? 0)      or
                    elt1.x + (elt1.width ? 0) < elt2.x      or
                    elt1.y > elt2.y + (elt2.height ? 0)     or
                    elt1.y + (elt1.height ? 0) < elt2.y)

        items = []
        fifo = [@]

        while fifo.length > 0
            top = fifo.splice(0, 1)[0]

            for elt in top.oversized when elt isnt item and collisionFunction item, elt then items.push elt
            for elt in top.contents  when elt isnt item and collisionFunction item, elt then items.push elt

            relatedChild = top.children[calculateDirection item, top]

            if isOversized item, relatedChild.create()
                for child of top.children when top.children[child].tree?
                    fifo.push top.children[child].tree

            else if relatedChild.tree?
                fifo.push relatedChild.tree

        items

    get: (params) ->
        @where params

    where: (params) ->
        validateElement params

        items = []
        fifo = [@]

        while fifo.length > 0
            top = fifo.splice(0, 1)[0]

            for elt in top.oversized
                check = true
                for key of params when params[key] isnt elt[key] then check = false
                items.push elt if check
            for elt in top.contents
                check = true
                for key of params when params[key] isnt elt[key] then check = false
                items.push elt if check

            relatedChild = top.children[calculateDirection params, top]

            if relatedChild.tree?
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

    find: (predicate) ->
        fifo = [@]
        items = []

        while fifo.length > 0
            top = fifo.splice(0, 1)[0]
            for i in top.oversized when predicate?(i) then items.push i
            for i in top.contents when predicate?(i) then items.push i

            for child of top.children when top.children[child].tree?
                fifo.push top.children[child].tree
        items

    filter: (validate) ->
        deepclone = (target) ->
            copycat = new Quadtree x: target.x, y: target.y, width: target.width, height: target.height, maxElements: target.maxElements
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
