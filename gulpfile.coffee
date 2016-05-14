gulp        = require 'gulp'
coffee      = require 'gulp-coffee'
uglify      = require 'gulp-uglify'
sourcemaps  = require 'gulp-sourcemaps'
mocha       = require 'gulp-mocha'
istanbul    = require 'gulp-istanbul'
rename      = require 'gulp-rename'
docco       = require 'gulp-docco'
minifyHTML  = require 'gulp-minify-html'
del         = require 'del'

paths =
    src: ['src/**/*.coffee']
    test: ['test/*.coffee']
    perf: ['test/perf/*.coffee']
    docindex: ['documentation/quadtree.html']

gulp.task 'clean', () ->
    del ['build']

gulp.task 'build', () ->
    gulp.src paths.src
        .pipe sourcemaps.init()
        .pipe coffee bare: true
        .pipe gulp.dest('build/js')
        .pipe uglify()
        .pipe sourcemaps.write()
        .pipe rename extname: '.min.js'
        .pipe gulp.dest 'build/js'


gulp.task 'test', ['build'], () ->
    gulp.src 'build/js/quadtree.js'
        .pipe istanbul()
        .pipe istanbul.hookRequire()
        .on 'finish', ->
            gulp.src paths.test, read: false
            .pipe mocha reporter: 'nyan'
            .pipe istanbul.writeReports()

gulp.task 'perf', ['build'], () ->
    gulp.src paths.perf, read: false
        .pipe mocha reporter: 'spec'

gulp.task 'watch', () ->
    gulp.watch [paths.src, paths.test], ['build', 'test']

gulp.task 'generatedoc', () ->
    gulp.src paths.src
        .pipe docco layout: 'linear'
        .pipe gulp.dest './documentation'

gulp.task 'doc', ['generatedoc'], () ->
    gulp.src paths.docindex
        .pipe rename 'index.html'
        .pipe gulp.dest './documentation'

gulp.task 'default', ['test']
