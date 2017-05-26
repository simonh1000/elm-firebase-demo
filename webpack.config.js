const webpack         = require('webpack');
var merge             = require( 'webpack-merge' );
var CopyWebpackPlugin = require('copy-webpack-plugin');
var path              = require('path');

var elmSource = path.join(__dirname, 'src');

var TARGET_ENV = process.env.npm_lifecycle_event === 'build' ? 'production' : 'development';

var common = {
    entry: './src/index.js',

    output: {
        path: path.join(__dirname, "dist"),
        filename: 'index.js'
    },

    resolve: {
        modules: [
            path.join(__dirname, "src"),
            "node_modules"
        ],
        extensions: ['.js', '.elm', '.scss']
    },
    plugins: [
        new webpack.NoEmitOnErrorsPlugin(),
        new CopyWebpackPlugin(
            [
                {
                    from: 'src/assets/images',
                    to: 'images/'
                },
                {
                    from: 'src/dist'
                },
                {
                    from: 'src/Firebase/*.config.js',
                    to: 'Firebase/[name].[ext]'
                }
            ]
        )
    ],
    module: {
        rules: [{
                test: /\.html$/,
                exclude: /node_modules/,
                loader: 'file-loader?name=[name].[ext]'
            },
            {
                test: /\.js$/,
                exclude: /node_modules/,
                use: {
                    loader: 'babel-loader',
                    options: {
                        // env: automatically determines the Babel plugins you need based on your supported environments
                        presets: ['env']
                    }
                }
            }, {
                test: /\.scss$/,
                exclude: [/elm-stuff/, /node_modules/],
                loaders: ["style-loader", "css-loader", "sass-loader"]
            },
            {
                test: /\.css$/,
                exclude: [/elm-stuff/, /node_modules/],
                loaders: ["style-loader", "css-loader"]
            },
            {
                test: /\.woff(2)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
                exclude: [/elm-stuff/, /node_modules/],
                loader: "url-loader",
                options: {
                    limit: 10000,
                    mimetype: "application/font-woff"
                }
            },
            {
                test: /\.(ttf|eot|svg)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
                exclude: [/elm-stuff/, /node_modules/],
                loader: "file-loader"
            }
        ]
    }
}
  if ( TARGET_ENV === 'development' ) {
    console.log( 'Building for dev...');
    module.exports =
        merge(common, {
            plugins: [
                new webpack.NamedModulesPlugin()
            ],
            module: {
                rules: [
                    {
                        test: /\.elm$/,
                        exclude: [/elm-stuff/, /node_modules/],
                        use: [{
                                loader: "elm-hot-loader"
                            },
                            {
                                loader: "elm-webpack-loader",
                                options: {
                                    debug: true
                                }
                            }
                        ]
                    }
                ]
            },
            devServer: {
                //   proxy: {
                //       "/": "http://localhost:9779"
                //   },
                inline: true,
                stats: 'errors-only',
                setup(app) {
                    // firebase messaging script needs to be able to find this route
                    app.get('/firebase-messaging-sw.js', (req, res) => {
                        res.sendFile(path.join(__dirname, 'src/dist/firebase-messaging-sw.js'));
                    })
                    app.get('/assets/:fname', (req, res) => {
                        res.sendFile(path.join(__dirname, 'src/assets/', req.params.fname));
                    })
                    app.get('/Firebase/:fname', (req, res) => {
                        res.sendFile(path.join(__dirname, 'src/Firebase/', req.params.fname));
                    })
                }
            }
        });
}

if ( TARGET_ENV === 'production' ) {
  console.log( 'Building for prod...');
  module.exports =
      merge(common, {
          module: {
              rules: [
                  {
                      test: /\.elm$/,
                      exclude: [/elm-stuff/, /node_modules/],
                      use: [
                          {
                              loader: "elm-webpack-loader"
                          }
                      ]
                  }
              ]
          }
      });
}
