gulp        = require 'gulp'
coffee      = require 'gulp-coffee'
coffeelint  = require 'gulp-coffeelint'
uglify      = require 'gulp-uglify'
filter      = require 'gulp-filter'
sourcemaps  = require 'gulp-sourcemaps'
mocha       = require 'gulp-mocha'
istanbul    = require 'gulp-istanbul'
rename      = require 'gulp-rename'
docco       = require 'gulp-docco'
del         = require 'del'

paths =
    src: ['src/**/*.coffee']
    demo: ['demo/**/*', 'build/js/quadtree.min.js', 'build/js/quadtree.min.js.map']
    test: ['test/*.coffee']
    perf: ['test/perf/*.coffee']
    docindex: ['docs/quadtree.html']

gulp.task 'clean', ->
    del ['build', 'docs', 'coverage']

gulp.task 'lint', ->
    gulp.src [paths.src..., paths.test..., paths.perf..., 'gulpfile.coffee']
        .pipe(coffeelint())
        .pipe(coffeelint.reporter())
        .pipe(coffeelint.reporter('fail'))

gulp.task 'build', ['lint'], ->
    gulp.src paths.src
        .pipe sourcemaps.init()
        .pipe coffee bare: true
        .pipe sourcemaps.write '.'
        .pipe gulp.dest('build/js')
        .pipe filter('**/*.js')
        .pipe uglify()
        .pipe rename extname: '.min.js'
        .pipe sourcemaps.write '.'
        .pipe gulp.dest 'build/js'

gulp.task 'pre-test', ['build'], ->
    gulp.src 'build/js/quadtree.js'
        .pipe istanbul()
        .pipe istanbul.hookRequire()

gulp.task 'test', ['pre-test'], ->
    gulp.src paths.test, read: false
        .pipe mocha reporter: 'nyan'
        .pipe istanbul.writeReports()

gulp.task 'perf', ['build'], ->
    gulp.src paths.perf, read: false
        .pipe mocha reporter: 'spec'

gulp.task 'watch', ->
    gulp.watch [paths.src, paths.test], ['build', 'test']

gulp.task 'generatedoc', ->
    gulp.src paths.src
        .pipe docco layout: 'linear'
        .pipe gulp.dest './docs'

gulp.task 'setupdemo', ->
    gulp.src paths.demo
        .pipe gulp.dest './docs/demo'

gulp.task 'copyassets', ->
    gulp.src 'assets/**/*'
        .pipe gulp.dest './docs/assets'

gulp.task 'doc', ['generatedoc', 'setupdemo', 'copyassets'], ->
    gulp.src paths.docindex
        .pipe rename 'index.html'
        .pipe gulp.dest './docs'

gulp.task 'watchdemo', ->
    gulp.watch ['./demo/**'], ['setupdemo']

gulp.task 'default', ['test']
