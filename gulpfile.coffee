gulp        = require 'gulp'
coffee      = require 'gulp-coffee'
uglify      = require 'gulp-uglify'
sourcemaps  = require 'gulp-sourcemaps'
mocha       = require 'gulp-mocha'
del         = require 'del'

paths =
    src: ['src/**/*.coffee']
    test: ['test/*.coffee']
    perf: ['test/perf/*.coffee']

gulp.task 'clean', () ->
    del ['build']

gulp.task 'build', () ->
    gulp.src paths.src
        .pipe sourcemaps.init()
        .pipe coffee bare: true
        .pipe uglify()
        .pipe sourcemaps.write()
        .pipe gulp.dest 'build/js'

gulp.task 'test', ['build'], () ->
    gulp.src paths.test, read: false
        .pipe mocha reporter: 'nyan'

gulp.task 'perf', ['build'], () ->
    gulp.src paths.perf, read: false
        .pipe mocha reporter: 'spec'

gulp.task 'watch', () ->
    gulp.watch [paths.src, paths.test], ['build', 'test']

gulp.task 'default', ['test']
