# quadtree-lib
# ============
#
# **Quadtree-lib** is an easy to use, developer friendly quadtree library
# which contains many helper methods to add, remove, iterate, filter, simulate
# collisions over 2d elements and more.
#
# The Quadtree class.
# -------------------
class Quadtree
    # ### Constructor

    # A quadtree constructor has 5 parameters :
    # - x & y coordinates which are always (0, 0) for the root tree.
    # - its dimensions (width & length), mandatory.
    # - the maximum number of elements before the leaf 'splits' into subtrees. (defaults to 1)
    constructor: ({@x, @y, @width, @height, @maxElements}) ->

        # An error is thrown when the width & length are not passed as constructor arguments.
        throw new Error "Missing quadtree dimensions." if not @width? or not @height?
        @x ?= 0
        @y ?= 0
        @maxElements ?= 1
        @contents = []
        @oversized = []
        @size = 0

        # Dimension & coordinates are checked, an error is thrown in case of bad input.
        throw new Error "Dimensions and coordinates must be positive integers." if @x < 0 or @y < 0 or @width < 1 or @height < 1
        throw new Error "The maximum number of elements before a split must be a positive integer." if @maxElements < 1

        that = @

        # The subtrees list, by position.
        @children = {
            # Northwest tree.
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
            # Northeast tree.
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
            # Southwest tree.
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
            # Southeast tree.
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
        # Adding a getter which lazily creates the tree.
        for child of @children
            @children[child].get = () ->
                if @tree? then @tree else @tree = @create(); @tree

    # ### Internal methods & vars

    # Retrieves the center coordinates of a rectangle.
    getCenter = (item) ->
        x: Math.floor((item.width  ? 1) / 2) + item.x
        y: Math.floor((item.height ? 1) / 2) + item.y

    # Validates a potential element of the tree.
    validateElement = (element) ->
        if not typeof element is "object" or not element.x? or not element.y? or element.x < 0 or element.y < 0
            throw new Error "Object must contain x or y positions as arguments, and they must be positive integers."
        if element?.width < 0 or element?.height < 0
            throw new Error "Width and height must be positive integers."

    # Determines the subtree which an element belongs to.
    calculateDirection = (element, tree) ->
        element
        quadCenter = getCenter tree

        if element.x < quadCenter.x
            if element.y < quadCenter.y then "NW"
            else "SW"
        else
            if element.y < quadCenter.y then "NE"
            else "SE"

    # Determines if an element is oversized.
    # An oversized element is an element 'too big' to fit into the tree.
    isOversized = (element, tree) ->
        element.x < tree.x or
        element.x + (element.width ? 0) >= tree.x + tree.width or
        element.y < tree.y or
        element.y + (element.height ? 0) >= tree.y + tree.height

    # Add getters and setters for coordinates and dimensions properties in order to automatically reorganize the elements on change.
    observe = (item, tree) ->
        writeAccessors = (propName) ->
            item["_#{propName}"] = item[propName]
            Object.defineProperty item, propName, {
                set: (val) ->
                    tree.remove @
                    @["_#{propName}"] = val
                    tree.push @
                get: ->
                    @["_#{propName}"]
                configurable: true
            }
        writeAccessors "x"
        writeAccessors "y"
        writeAccessors "width"
        writeAccessors "height"

    # ### Exposed methods

    # Add an element to the quadtree.
    # Elements can be observed to reorganize them into the quadtree automatically when their coordinates or dimensions are manually changed (for ex. obj.x = ...).
    push: (item, doObserve) ->
        validateElement item
        observe item, @ if doObserve

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

    # Removes an element from the quadtree.
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

    # Returns an array of elements which collides with the `item` argument.
    # `item` being an object having x, y, width & height properties.

    # The default collision function is a basic bounding box algorithm.
    # You can change it by providing a function as a second argument.
    #```javascript
    #colliding({x: 10, y: 20}, function(element1, element2){
    #    return //Predicate
    #})
    #```
    colliding: (item, collisionFunction) ->
        validateElement item

        boundingBoxCollision = (elt1, elt2) ->
            not(elt1.x > elt2.x + (elt2.width ? 0)      or
                elt1.x + (elt1.width ? 0) < elt2.x      or
                elt1.y > elt2.y + (elt2.height ? 0)     or
                elt1.y + (elt1.height ? 0) < elt2.y)

        collisionFunction ?= boundingBoxCollision

        items = []
        fifo  = [@]

        while fifo.length > 0
            top = fifo.splice(0, 1)[0]

            for elt in top.oversized when elt isnt item and collisionFunction item, elt then items.push elt
            for elt in top.contents  when elt isnt item and collisionFunction item, elt then items.push elt

            relatedChild = top.children[calculateDirection item, top]

            if isOversized item, relatedChild.create()
                for child of top.children
                    if top.children[child].tree? and boundingBoxCollision(top.children[child].tree, item)
                        fifo.push top.children[child].tree

            else if relatedChild.tree?
                fifo.push relatedChild.tree

        items

    # Alias of `where`.
    get: (query) ->
        @where query
    # Returns an array of elements that match the `query` argument.
    where: (query) ->
        # Naïve parsing (missing coordinates)
        if typeof query is "object" and not query.x? and not query.y?
            return @find (elt) ->
                check = true
                for key of query when query[key] isnt elt[key] then check = false
                check

        # Optimised parsing
        validateElement query

        items = []
        fifo = [@]

        while fifo.length > 0
            top = fifo.splice(0, 1)[0]

            for elt in top.oversized
                check = true
                for key of query when query[key] isnt elt[key] then check = false
                items.push elt if check
            for elt in top.contents
                check = true
                for key of query when query[key] isnt elt[key] then check = false
                items.push elt if check

            relatedChild = top.children[calculateDirection query, top]

            if relatedChild.tree?
                fifo.push relatedChild.tree

        items

    # For each element of the quadtree, performs the `action` function.
    #```javascript
    #quad.each(function(item){ console.log(item) })
    #```
    each: (action) ->
        fifo = [@]

        while fifo.length > 0
            top = fifo.splice(0, 1)[0]
            for i in top.oversized then action?(i)
            for i in top.contents then action?(i)

            for child of top.children when top.children[child].tree?
                fifo.push top.children[child].tree
        @

    # Returns an array of elements which validate the predicate.
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

    # Returns a **cloned** `Quadtree` object which contains only the elements that validate the predicate.
    filter: (predicate) ->
        deepclone = (target) ->
            copycat = new Quadtree x: target.x, y: target.y, width: target.width, height: target.height, maxElements: target.maxElements
            copycat.size = 0
            for child of target.children when target.children[child].tree?
                copycat.children[child].tree = deepclone target.children[child].tree
                copycat.size += copycat.children[child].tree?.size ? 0

            for item in target.oversized when not predicate? or predicate?(item)
                copycat.oversized.push item
            for item in target.contents when not predicate? or predicate?(item)
                copycat.contents.push item

            copycat.size += copycat.oversized.length + copycat.contents.length
            if copycat.size is 0 then null else copycat

        deepclone @

    # Opposite of filter
    reject: (predicate) ->
        @filter (i) ->
            not predicate?(i)

    # Visits each tree & subtree contained in the `Quadtree` object.
    # For each node, performs the `action` function, inside which `this` is bound to the node tree object.
    visit: (action) ->
        fifo = [@]

        while fifo.length > 0
            that = fifo.splice(0, 1)[0]
            action.bind(that)()

            for child of that.children when that.children[child].tree?
                fifo.push that.children[child].tree
        @

# Require export.
module?.exports = Quadtree
