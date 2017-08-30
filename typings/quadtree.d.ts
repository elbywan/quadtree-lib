export as namespace Quadtree
export = Quadtree

declare class Quadtree<T extends Quadtree.QuadtreeItem> {

    /**
     * The Quadtree class constructor.
     * @param options Object containing the tree properties.
     *  - width, height : dimensions.
     *  - maxElements: maximum number of elements per leaf, further elements cause a split.
     *  - x, y : these are used internally by the library to position subtrees.
     */
    constructor(options: {
        x?: number,
        y?: number,
        width: number,
        height: number,
        maxElements?: number
    })

    /**
     * Removes all elements from the quadtree and restores pristine state.
     */
    public clear() : void

    /**
     * Add an element to the quadtree.
     *
     * Elements can be observed to reorganize them into the quadtree automatically whenever their coordinates or dimensions are set (for ex. obj.x = ...).
     *
     * @param item Element to add.
     * @param doObserve Observes the element and removes/add it to the quadtree when its dimensions/coordinates are modified.
     */
    public push(item: T, doObserve?: boolean): Quadtree<T>
    /**
     * Push an array of elements.
     *
     * @param items Array of elements.
     * @param doObserve Observes the elements and removes/add them to the quadtree when their dimensions/coordinates are modified.
     */
    public pushAll(items: Array<T>, doObserve?: boolean) : Quadtree<T>
    /**
     * Removes an element from the quadtree.
     */
    public remove(item: T) : boolean
    /**
     * Returns an array of elements which collides with the `item` argument.
     *`item` being an object having x, y, width & height properties.
     *
     *The default collision function is a basic bounding box algorithm.
     *You can change it by providing a function as a second argument.
     *```javascript
     *colliding({x: 10, y: 20}, function(element1, element2){
     *    return //Predicate
     *})
     *```
     */
    public colliding(item: Quadtree.QuadtreeItem, collisionFunction?: (elt1: T, elt2: T) => boolean) : Array<T>
    /** Performs an action on elements which collides with the `item` argument.
    * `item` being an object having x, y, width & height properties.
    *
    * The default collision function is a basic bounding box algorithm.
    * You can change it by providing a function as a third argument.
    *```javascript
    *onCollision(
    *   { x: 10, y: 20 },
    *   function(item) {
    *       // stuff //
    *   },
    *   function(element1, element2) {
    *       return // Place predicate here //
    *})
    * ```
    */
    public onCollision(item: Quadtree.QuadtreeItem, callback: Function, collisionFunction ?: (elt1: T, elt2: T) => boolean) : void
    /**
     * Returns an array of elements that match the `query` argument.
     */
    public get(query: Object): Array<T>
    /**
     * Returns an array of elements that match the `query` argument.
     */
    public where(query: Object) : Array<T>
    /**
     * For each element of the quadtree, performs the `action` function.
     *
     * ```javascript
     * quad.each(function(item){ console.log(item) })
     * ```
     */
    public each(action: (elt: T) => void) : Quadtree<T>
    /**
     * Returns an array of elements which validate the predicate.
     */
    public find(predicate: (elt: T) => boolean) : Array<T>
    /**
     * Returns a **cloned** `Quadtree` object which contains only the elements that validate the predicate.
     */
    public filter(predicate: (elt: T) => boolean) : Quadtree<T>
    /**
     * Opposite of filter.
     */
    public reject(predicate: (elt: T) => boolean) : Quadtree<T>
    /**
     * Visits each tree & subtree contained in the `Quadtree` object.
     * For each node, performs the `action` function, inside which `this` is bound to the node tree object.
     */
    public visit(action: (tree: Quadtree<T>) => void) : Quadtree<T>
    /**
     * Pretty printing function.
     */
    public pretty() : string
}

declare namespace Quadtree {
    export type QuadtreeItem = { x: number, y: number, width?: number, height?: number, [extras: string]: any }
}
