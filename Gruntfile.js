/**
 *
 *
 *   PrismTech licenses this file to You under the Apache License, Version 2.0
 *   (the "License"); you may not use this file except in compliance with the
 *   License and with the PrismTech Vortex product. You may obtain a copy of the
 *   License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in writing, software
 *   distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 *   WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 *   License and README for the specific language governing permissions and
 *   limitations under the License.
 *
 **/

var path = require("path");

module.exports = function(grunt) {

    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),
        paths: {
            dist: ".dist"
        },
        coffee: {
            coffee_to_js: {
                options: {
                    bare: false,
                    sourceMap: false
                },
                expand: true,
                flatten: false,
                cwd: "src",
                src: ["**/*.coffee"],
                dest: "lib",
                ext: ".js"
            }
        },
        jshint: {
            options: {
                jshintrc:true
                // http://www.jshint.com/docs/options/
                //"asi": true,      // allow missing semicolons
                //"curly": true,    // require braces
                //"eqnull": true,   // ignore ==null
                //"forin": true,    // require property filtering in "for in" loops
                //"immed": true,    // require immediate functions to be wrapped in ( )
                //"nonbsp": true,   // warn on unexpected whitespace breaking chars
                ////"strict": true, // commented out for now as it causes 100s of warnings, but want to get there eventually
                //"loopfunc": true, // allow functions to be defined in loops
                //"sub": true       // don't warn that foo['bar'] should be written as foo.bar
            }
        },
        //concat: {
        //    options: {
        //        separator: ";"
        //    },
        //    build: {
        //        src:[
        //            "./vortex.js",
        //            "src/coffez.js",
        //            "src/config.js",
        //            "src/control-commands.js",
        //            "src/control-link.js",
        //            "src/dds-runtime.js",
        //            "src/dds.js"
        //        ],
        //        dest: "lib/node-vortex.js"
        //    },
        //},
        uglify: {
            build: {
                files: {
                    'lib/vortex-dds.min.js': 'lib/vortex-dds.js'
                }
            }
        },
        attachCopyright: {
            js: {
                src: [
                    'lib/vortex-dds.min.js'
                ]
            }
        },
        clean: {
            build: {
                src: [
                    "lib/vortex-dds.js"
                ]
            },
            release: {
                src: [
                    '<%= paths.dist %>'
                ]
            }
        },
    });

    grunt.loadNpmTasks('grunt-contrib-concat');
    grunt.loadNpmTasks('grunt-contrib-uglify');
    grunt.loadNpmTasks('grunt-contrib-clean');
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-concurrent');
    grunt.loadNpmTasks('grunt-nodemon');
    grunt.loadNpmTasks('grunt-contrib-compress');
    grunt.loadNpmTasks('grunt-contrib-copy');
    grunt.loadNpmTasks('grunt-chmod');

    grunt.registerMultiTask('attachCopyright', function() {
        var files = this.data.src;
        var copyright = "/**\n"+
            " * Copyright 2015 PrismTech (http://www.prismtech.com)\n"+
            " *\n"+
            " * Licensed under the Apache License, Version 2.0 (the \"License\");\n"+
            " * you may not use this file except in compliance with the License.\n"+
            " * You may obtain a copy of the License at\n"+
            " *\n"+
            " * http://www.apache.org/licenses/LICENSE-2.0\n"+
            " *\n"+
            " * Unless required by applicable law or agreed to in writing, software\n"+
            " * distributed under the License is distributed on an \"AS IS\" BASIS,\n"+
            " * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n"+
            " * See the License for the specific language governing permissions and\n"+
            " * limitations under the License.\n"+
            " **/\n";

        if (files) {
            for (var i=0;i<files.length;i++) {
                var file = files[i];
                if (!grunt.file.exists(file)) {
                    grunt.log.warn('File '+ file + ' not found');
                    return false;
                } else {
                    var content = grunt.file.read(file);
                    if (content.indexOf(copyright) == -1) {
                        content = copyright+content;
                        if (!grunt.file.write(file, content)) {
                            return false;
                        }
                        grunt.log.writeln("Attached copyright to "+file);
                    } else {
                        grunt.log.writeln("Copyright already on "+file);
                    }
                }
            }
        }
    });

    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.registerTask('compile', ['coffee']);

    grunt.registerTask('default',
        'Builds editor content then runs code style checks and unit tests on all components',
        ['coffee', 'build','test-core','test-editor','test-nodes']);

    grunt.registerTask('build',
        'Builds editor content',
        ['clean:build', 'coffee','concat:build','concat:vendor','uglify:build','copy:build','attachCopyright']);
};