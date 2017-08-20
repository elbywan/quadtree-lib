# quadtree-lib
# ============
#
# **Quadtree-lib** is an easy to use, developer friendly quadtree library
# which contains many helper methods to add, remove, iterate, filter, simulate
# collisions over 2d elements and more.

# #### UMD bundling related code
((root, factory) ->
    if typeof define is 'function' and define.amd
        define [], factory
    else if typeof exports is 'object' and module.exports
        module.exports = factory()
    else
        root['Quadtree'] = factory()
) @, (-> class Quadtree
    # The Quadtree class
    # -------------------

    # ### Constructor

    # The quadtree constructor accepts a single parameter object containing the following properties :
    # - width / length : dimensions of the quadtree. [ *mandatory* ]
    # - maxElements : the maximum number of elements before the leaf 'splits' into subtrees. [ *defaults to 1* ]
    # - x / y : these coordinates are used internally by the library to position subtrees. [ *internal use only* ]
    constructor: ({ @x, @y, @width, @height, @maxElements }) ->

        # An error is thrown when the width & length are not passed as constructor arguments.
        throw new Error 'Missing quadtree dimensions.' if not @width? or not @height?
        @x ?= 0
        @y ?= 0
        @maxElements ?= 1
        @contents = []
        @oversized = []
        @size = 0

        # Dimension & coordinates are checked, an error is thrown in case of bad input.
        throw new Error 'Dimensions must be positive integers.' if @width < 1 or @height < 1
        throw new Error 'Coordinates must be integers' if not Number.isInteger(@x) or not Number.isInteger(@y)
        throw new Error 'The maximum number of elements before a split must be a positive integer.' if @maxElements < 1

        that = @

        # The subtrees list, by position.
        @children = {
            # Northwest tree.
            NW:
                create: ->
                    new Quadtree({
                        x: that.x
                        y: that.y
                        width: Math.max (Math.floor that.width / 2), 1
                        height: Math.max (Math.floor that.height / 2), 1
                        maxElements: that.maxElements
                    })
                tree: null
            # Northeast tree.
            NE:
                create: ->
                    new Quadtree({
                        x: that.x + Math.max (Math.floor that.width / 2), 1
                        y: that.y
                        width: Math.ceil that.width / 2
                        height: Math.max (Math.floor that.height / 2), 1
                        maxElements: that.maxElements
                    })
                tree: null
            # Southwest tree.
            SW:
                create: ->
                    new Quadtree({
                        x: that.x
                        y: that.y + Math.max (Math.floor that.height / 2), 1
                        width: Math.max (Math.floor that.width / 2), 1
                        height: Math.ceil that.height / 2
                        maxElements: that.maxElements
                    })
                tree: null
            # Southeast tree.
            SE:
                create: ->
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
            @children[child].get = ->
                if @tree? then @tree else @tree = @create(); @tree

    # ### Internal methods & vars

    # Retrieves the center coordinates of a rectangle.
    getCenter = (item) ->
        x: Math.floor((item.width  ? 1) / 2) + item.x
        y: Math.floor((item.height ? 1) / 2) + item.y

    # Bounding box collision algorithm.
    boundingBoxCollision = (elt1, elt2) ->
        not(elt1.x >= elt2.x + (elt2.width ? 1)      or
            elt1.x + (elt1.width ? 1) <= elt2.x      or
            elt1.y >= elt2.y + (elt2.height ? 1)     or
            elt1.y + (elt1.height ? 1) <= elt2.y)

    # Determines which subtree an element belongs to.
    calculateDirection = (element, tree) ->
        quadCenter = getCenter tree

        if element.x < quadCenter.x
            if element.y < quadCenter.y then 'NW'
            else 'SW'
        else
            if element.y < quadCenter.y then 'NE'
            else 'SE'

    # Validates a potential element of the tree.
    validateElement = (element) ->
        if not (typeof element is 'object')
            throw new Error 'Element must be an Object.'
        if not element.x? or not element.y?
            throw new Error 'Coordinates properties are missing.'
        if element?.width < 0 or element?.height < 0
            throw new Error 'Width and height must be positive integers.'

    # Returns splitted coordinates and dimensions.
    splitTree = (tree) ->
        leftWidth    = Math.max (Math.floor tree.width / 2), 1
        rightWidth   = Math.ceil tree.width / 2
        topHeight    = Math.max (Math.floor tree.height / 2), 1
        bottomHeight = Math.ceil tree.height / 2
        NW:
            x: tree.x
            y: tree.y
            width: leftWidth
            height: topHeight
        NE:
            x: tree.x + leftWidth
            y: tree.y
            width: rightWidth
            height: topHeight
        SW:
            x: tree.x
            y: tree.y + topHeight
            width: leftWidth
            height: bottomHeight
        SE:
            x: tree.x + leftWidth
            y: tree.y + topHeight
            width: rightWidth
            height: bottomHeight

    # Determines wether an element fits into subtrees.
    fitting = (element, tree) ->
        where = []
        for direction, coordinates of splitTree tree when boundingBoxCollision element, coordinates
            where.push direction
        where

    # Add getters and setters for coordinates and dimensions properties in order to automatically reorganize the elements on change.
    observe = (item, tree) ->
        writeAccessors = (propName) ->
            item["_#{propName}"] = item[propName]
            Object.defineProperty item, propName, {
                set: (val) ->
                    tree.remove @, true
                    @["_#{propName}"] = val
                    tree.push @
                get: ->
                    @["_#{propName}"]
                configurable: true
            }
        writeAccessors 'x'
        writeAccessors 'y'
        writeAccessors 'width'
        writeAccessors 'height'

    # Remove getters and setters and restore previous properties
    unobserve = (item) ->
        unwriteAccessors = (propName) ->
            if not item["_#{propName}"]? then return
            delete item[propName]
            item[propName] = item["_#{propName}"]
            delete item["_#{propName}"]
        unwriteAccessors 'x'
        unwriteAccessors 'y'
        unwriteAccessors 'width'
        unwriteAccessors 'height'

    # ### Exposed methods

    # Removes all elements from the quadtree and restores it to pristine state.
    clear: ->
        @contents = []
        @oversized = []
        @size = 0
        for child of @children
            @children[child].tree = null

    # Add an element to the quadtree.
    # Elements can be observed to reorganize them into the quadtree automatically whenever their coordinates or dimensions are set (for ex. obj.x = ...).
    push: (item, doObserve) ->
        @pushAll([item], doObserve)

    # Push an array of elements.
    pushAll: (items, doObserve) ->
        for item in items
            validateElement item
            observe item, @ if doObserve

        fifo = [tree: @, elements: items]

        while fifo.length > 0
            { tree, elements } = fifo.shift()

            fifoCandidates = { NW: null, NE: null, SW: null, SE: null }

            for element in elements
                tree.size++

                fits = fitting element, tree

                if fits.length isnt 1 or tree.width is 1 or tree.height is 1
                    tree.oversized.push element

                else if (tree.size - tree.oversized.length) <= tree.maxElements
                    tree.contents.push element

                else
                    direction = fits[0]
                    relatedChild = tree.children[direction]
                    fifoCandidates[direction] ?= { tree: relatedChild.get(), elements: [] }
                    fifoCandidates[direction].elements.push(element)

                    for content in tree.contents
                        contentDir = (fitting content, tree)[0]
                        fifoCandidates[contentDir] ?= { tree: tree.children[contentDir].get(), elements: [] }
                        fifoCandidates[contentDir].elements.push(content)

                    tree.contents = []

            for direction, candidate of fifoCandidates
                if candidate? then fifo.push candidate

        @

    # Removes an element from the quadtree.
    remove: (item, stillObserve) ->
        validateElement item

        index = @oversized.indexOf item
        if index > -1
            @oversized.splice index, 1
            @size--
            if not stillObserve then unobserve item
            return true

        index = @contents.indexOf item
        if index > -1
            @contents.splice index, 1
            @size--
            if not stillObserve then unobserve item
            return true

        relatedChild = @children[calculateDirection item, @]

        if relatedChild.tree? and relatedChild.tree.remove item, stillObserve
            @size--
            relatedChild.tree = null if relatedChild.tree.size is 0
            return true

        false

    # Returns an array of elements which collides with the `item` argument.
    # `item` being an object having x, y, width & height properties.

    # The default collision function is a basic bounding box algorithm.
    # You can change it by providing a function as a second argument.
    #```javascript
    #colliding({x: 10, y: 20}, function(element1, element2) {
    #    return // Place predicate here //
    #})
    #```
    colliding: (item, collisionFunction = boundingBoxCollision) ->
        validateElement item

        items = []
        fifo  = [@]

        while fifo.length > 0
            top = fifo.shift()

            for elt in top.oversized when elt isnt item and collisionFunction item, elt then items.push elt
            for elt in top.contents  when elt isnt item and collisionFunction item, elt then items.push elt

            fits = fitting item, top

            # Special case for elements located outside of the quadtree on the right / bottom side
            if fits.length is 0
                fits = []
                if item.x >= top.x + top.width
                    fits.push 'NE'
                if item.y >= top.y + top.height
                    fits.push 'SW'
                if fits.length > 0
                    if fits.length is 1 then fits.push 'SE' else fits = ['SE']

            for child in fits when top.children[child].tree?
                fifo.push top.children[child].tree

        items

    # Performs an action on elements which collides with the `item` argument.
    # `item` being an object having x, y, width & height properties.

    # The default collision function is a basic bounding box algorithm.
    # You can change it by providing a function as a third argument.
    #```javascript
    #onCollision(
    #    {x: 10, y: 20},
    #    function(item) { /* stuff */ },
    #    function(element1, element2) {
    #        return // Place predicate here //
    #})
    #```
    onCollision: (item, callback, collisionFunction = boundingBoxCollision) ->
        validateElement item

        fifo  = [@]

        while fifo.length > 0
            top = fifo.shift()

            for elt in top.oversized when elt isnt item and collisionFunction item, elt then callback elt
            for elt in top.contents  when elt isnt item and collisionFunction item, elt then callback elt

            fits = fitting item, top

            # Special case for elements located outside of the quadtree on the right / bottom side
            if fits.length is 0
                fits = []
                if item.x >= top.x + top.width
                    fits.push 'NE'
                if item.y >= top.y + top.height
                    fits.push 'SW'
                if fits.length > 0
                    if fits.length is 1 then fits.push 'SE' else fits = ['SE']

            for child in fits when top.children[child].tree?
                fifo.push top.children[child].tree

        return null

    # Alias of `where`.
    get: (query) ->
        @where query
    # Returns an array of elements that match the `query` argument.
    where: (query) ->
        # Naïve parsing (missing coordinates)
        if typeof query is 'object' and (not query.x? or not query.y?)
            return @find (elt) ->
                check = true
                for key of query when query[key] isnt elt[key] then check = false
                check

        # Optimised parsing
        validateElement query

        items = []
        fifo = [@]

        while fifo.length > 0
            top = fifo.shift()

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
    #quad.each(function(item) { console.log(item) })
    #```
    each: (action) ->
        fifo = [@]

        while fifo.length > 0
            top = fifo.shift()
            for i in top.oversized then action?(i)
            for i in top.contents then action?(i)

            for child of top.children when top.children[child].tree?
                fifo.push top.children[child].tree
        @

    # Returns an array of elements which validates the predicate.
    find: (predicate) ->
        fifo = [@]
        items = []

        while fifo.length > 0
            top = fifo.shift()
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

    # Opposite of filter.
    reject: (predicate) ->
        @filter (i) ->
            not predicate?(i)

    # Visits each tree & subtree contained in the `Quadtree` object.
    # For each node, performs the `action` function, inside which `this` is bound to the node tree object.
    visit: (action) ->
        fifo = [@]

        while fifo.length > 0
            that = fifo.shift()
            action.bind(that)()

            for child of that.children when that.children[child].tree?
                fifo.push that.children[child].tree
        @

    # Pretty printing function.
    pretty: ->
        str = ''

        indent = (level) ->
            res = ''
            res += '   ' for times in [level...0]
            res

        fifo  = [{ label: 'ROOT', tree: @, level: 0 }]
        while fifo.length > 0
            top = fifo.shift()
            indentation = indent(top.level)
            str += """
                   #{indentation}| #{top.label}
                   #{indentation}| ------------\n
                   """

            if top.tree.oversized.length > 0
                str += """
                       #{indentation}| * Oversized elements *
                       #{indentation}|   #{top.tree.oversized}\n
                       """

            if top.tree.contents.length > 0
                str += """
                       #{indentation}| * Leaf content *
                       #{indentation}|   #{top.tree.contents}\n
                       """

            isParent = false
            for child of top.tree.children when top.tree.children[child].tree?
                isParent = true
                fifo.unshift { label: child, tree: top.tree.children[child].tree, level: top.level + 1 }

            if isParent then str += "#{indentation}└──┐\n"

        str
)
