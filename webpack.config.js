const path = require("path");
const webpack = require("webpack");
const { merge } = require("webpack-merge");

const ClosurePlugin = require("closure-webpack-plugin");
const CopyWebpackPlugin = require("copy-webpack-plugin");
const HTMLWebpackPlugin = require("html-webpack-plugin");
const { CleanWebpackPlugin } = require("clean-webpack-plugin");

// Production CSS assets - separate, minimised file
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const OptimizeCSSAssetsPlugin = require("optimize-css-assets-webpack-plugin");

// Workbox: service worker
const WorkboxWebpackPlugin = require("workbox-webpack-plugin");

const Dotenv = require("dotenv-webpack");

var MODE =
    process.env.npm_lifecycle_event === "prod" ? "production" : "development";
var withDebug = !process.env["npm_config_nodebug"] && MODE == "development";

console.log(
    "\x1b[36m%s\x1b[0m",
    `** elm-webpack-starter: mode "${MODE}", withDebug: ${withDebug}\n`
);

var common = {
    mode: MODE,
    entry: "./src/index.js",
    output: {
        path: path.join(__dirname, "dist"),
        publicPath: "/",
        // FIXME webpack -p automatically adds hash when building for production
        filename: MODE == "production" ? "[name]-[hash].js" : "index.js",
    },
    plugins: [
        new HTMLWebpackPlugin({
            // Use this template to get basic responsive meta tags
            template: "src/index.html",
            // inject details of output file at end of body
            inject: "body",
        }),
        new Dotenv(),
        new webpack.DefinePlugin({
            VERSION: JSON.stringify(require("./package.json").version),
        }),
    ],
    resolve: {
        modules: [path.join(__dirname, "src"), "node_modules"],
        extensions: [".js", ".elm", ".scss", ".png"],
    },
    module: {
        rules: [
            {
                test: /\.js$/,
                exclude: /node_modules/,
                use: {
                    loader: "babel-loader",
                },
            },
            {
                test: /\.scss$/,
                exclude: [/elm-stuff/, /node_modules/],
                // see https://github.com/webpack-contrib/css-loader#url
                loaders: [
                    "style-loader",
                    "css-loader?url=false",
                    "sass-loader",
                ],
            },
            {
                test: /\.css$/,
                exclude: [/elm-stuff/, /node_modules/],
                loaders: ["style-loader", "css-loader?url=false"],
            },
            {
                test: /\.woff(2)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
                exclude: [/elm-stuff/, /node_modules/],
                loader: "url-loader",
                options: {
                    limit: 10000,
                    mimetype: "application/font-woff",
                },
            },
            {
                test: /\.(ttf|eot|svg)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
                exclude: [/elm-stuff/, /node_modules/],
                loader: "file-loader",
            },
            {
                test: /\.(jpe?g|png|gif|svg)$/i,
                exclude: [/elm-stuff/, /node_modules/],
                loader: "file-loader",
            },
        ],
    },
};

if (MODE === "development") {
    module.exports = merge(common, {
        optimization: {
            // Prevents compilation errors causing the hot loader to lose state
            noEmitOnErrors: true,
        },
        plugins: [
            // adds a pre-cache line to my service worker (GenerateSW could create the SW from scratch if preferred),
            // and saves it to the correct location in dest
            new WorkboxWebpackPlugin.InjectManifest({
                swSrc: "./src/assets/service-worker.js",
                swDest: "service-worker.js",
            }),
        ],
        module: {
            rules: [
                {
                    test: /\.elm$/,
                    exclude: [/elm-stuff/, /node_modules/],
                    use: [
                        { loader: "elm-hot-webpack-loader" },
                        {
                            loader: "elm-webpack-loader",
                            options: {
                                // add Elm's debug overlay to output
                                debug: withDebug,
                                //
                                forceWatch: true,
                            },
                        },
                    ],
                },
            ],
        },
        devServer: {
            inline: true,
            stats: {
                errors: true,
                errorDetails: true,
                warnings: true,
                reasons: true,
                version: true,
                hash: false,
                timings: false,
                children: false,
                chunks: false,
                modules: false,
                source: false,
                publicPath: false,
            },
            contentBase: path.join(__dirname, "src/assets"),
            historyApiFallback: true,
            // feel free to delete this section if you don't need anything like this
            before(app) {
                // Make fbsw.config.js available
                app.get("/Firebase/:fname", (req, res) => {
                    console.log(
                        "[devserver] Firebase directory",
                        req.params.fname
                    );
                    res.sendFile(
                        path.join(__dirname, "src/Firebase/", req.params.fname)
                    );
                });
            },
        },
    });
}

if (MODE === "production") {
    module.exports = merge(common, {
        optimization: {
            minimizer: [
                new ClosurePlugin(
                    { mode: "STANDARD" },
                    {
                        // compiler flags here
                        //
                        // for debugging help, try these:
                        //
                        // formatting: 'PRETTY_PRINT',
                        // debug: true
                        // renaming: false
                    }
                ),
                new OptimizeCSSAssetsPlugin({}),
            ],
        },
        plugins: [
            // Delete everything from output-path (/dist) and report to user
            new CleanWebpackPlugin({
                root: __dirname,
                exclude: [],
                verbose: true,
                dry: false,
            }),
            // Copy specific static assets
            new CopyWebpackPlugin({
                patterns: [
                    { from: "manifest.json", context: "src/assets" },
                    { from: "firebase-messaging-sw.js", context: "src/assets" },
                    {
                        from: "config",
                        to: "config",
                        context: "src/assets",
                    },
                    {
                        from: "images",
                        to: "images",
                        context: "src/assets",
                    },
                ],
            }),
            new MiniCssExtractPlugin({
                // Options similar to the same options in webpackOptions.output
                // both options are optional
                filename: "[name]-[hash].css",
            }),
            // adds a pre-cache line to my service worker (GenerateSW creates the SW from scratch if preferred),
            // and saves it to the correct location in dest
            new WorkboxWebpackPlugin.InjectManifest({
                swSrc: "./src/assets/service-worker.js",
                swDest: "service-worker.js",
            }),
        ],
        module: {
            rules: [
                {
                    test: /\.elm$/,
                    exclude: [/elm-stuff/, /node_modules/],
                    use: {
                        loader: "elm-webpack-loader",
                        options: {
                            optimize: true,
                        },
                    },
                },
                {
                    test: /\.css$/,
                    exclude: [/elm-stuff/, /node_modules/],
                    loaders: [
                        MiniCssExtractPlugin.loader,
                        "css-loader?url=false",
                    ],
                },
                {
                    test: /\.scss$/,
                    exclude: [/elm-stuff/, /node_modules/],
                    loaders: [
                        MiniCssExtractPlugin.loader,
                        "css-loader?url=false",
                        "sass-loader",
                    ],
                },
            ],
        },
    });
}
