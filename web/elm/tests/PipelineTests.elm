module PipelineTests exposing (..)

import Char
import Expect exposing (..)
import Html.Attributes as Attr
import Layout
import Pipeline exposing (update, Msg(..))
import QueryString
import RemoteData exposing (WebData)
import Routes
import Test exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector exposing (attribute, containing, id, style, tag, text, Selector)
import Time exposing (Time)
import TopBar


all : Test
all =
    describe "Pipeline"
        [ describe "update" <|
            let
                resetFocus =
                    (\_ -> Cmd.map (\_ -> Noop) Cmd.none)

                defaultModel : Pipeline.Model
                defaultModel =
                    { ports = { render = (\( _, _ ) -> Cmd.none), title = (\_ -> Cmd.none) }
                    , pipelineLocator = { teamName = "some-team", pipelineName = "some-pipeline" }
                    , pipeline = RemoteData.NotAsked
                    , fetchedJobs = Nothing
                    , fetchedResources = Nothing
                    , renderedJobs = Nothing
                    , renderedResources = Nothing
                    , concourseVersion = "some-version"
                    , turbulenceImgSrc = "some-turbulence-img-src"
                    , experiencingTurbulence = False
                    , route = { logical = Routes.Pipeline "" "", queries = QueryString.empty, page = Nothing, hash = "" }
                    , selectedGroups = []
                    , hideLegend = False
                    , hideLegendCounter = 0
                    }
            in
                [ test "HideLegendTimerTicked" <|
                    \_ ->
                        Expect.equal
                            (1 * Time.second)
                        <|
                            .hideLegendCounter <|
                                Tuple.first <|
                                    update (HideLegendTimerTicked 0) defaultModel
                , test "HideLegendTimeTicked reaches timeout" <|
                    \_ ->
                        Expect.equal
                            True
                        <|
                            .hideLegend <|
                                Tuple.first <|
                                    update (HideLegendTimerTicked 0) { defaultModel | hideLegendCounter = 10 * Time.second }
                , test "ShowLegend" <|
                    \_ ->
                        let
                            updatedModel =
                                Tuple.first <|
                                    update ShowLegend { defaultModel | hideLegend = True, hideLegendCounter = 3 * Time.second }
                        in
                            Expect.equal
                                ( False, 0 )
                            <|
                                ( .hideLegend updatedModel, .hideLegendCounter updatedModel )
                , test "KeyPressed" <|
                    \_ ->
                        Expect.equal
                            ( defaultModel, Cmd.none )
                        <|
                            update (KeyPressed (Char.toCode 'a')) defaultModel
                , test "KeyPressed f" <|
                    \_ ->
                        Expect.notEqual
                            ( defaultModel, Cmd.none )
                        <|
                            update (KeyPressed (Char.toCode 'f')) defaultModel
                , test "top bar is 56px tall with dark grey background" <|
                    \_ ->
                        init "/teams/team/pipelines/pipeline"
                            |> Layout.view
                            |> Query.fromHtml
                            |> Query.find [ id "top-bar-app" ]
                            |> Query.has [ style [ ( "background-color", "#1e1d1d" ), ( "height", "56px" ) ] ]
                , test "top bar lays out contents horizontally" <|
                    \_ ->
                        init "/teams/team/pipelines/pipeline"
                            |> Layout.view
                            |> Query.fromHtml
                            |> Query.find [ id "top-bar-app" ]
                            |> Query.has [ style [ ( "display", "inline-block" ) ] ]
                , test "top bar centers contents vertically" <|
                    \_ ->
                        init "/teams/team/pipelines/pipeline"
                            |> Layout.view
                            |> Query.fromHtml
                            |> Query.find [ id "top-bar-app" ]
                            |> Query.has [ style [ ( "align-items", "center" ) ] ]
                , test "top bar maximizes spacing between the left and right navs" <|
                    \_ ->
                        init "/teams/team/pipelines/pipeline"
                            |> Layout.view
                            |> Query.fromHtml
                            |> Query.find [ id "top-bar-app" ]
                            |> Query.has [ style [ ( "justify-content", "space-between" ), ( "left", "0" ), ( "right", "0" ) ] ]
                , test "top bar is sticky" <|
                    \_ ->
                        init "/teams/team/pipelines/pipeline"
                            |> Layout.view
                            |> Query.fromHtml
                            |> Query.find [ id "top-bar-app" ]
                            |> Query.has [ style [ ( "z-index", "100" ), ( "position", "fixed" ) ] ]
                , test "both navs are laid out horizontally" <|
                    \_ ->
                        init "/teams/team/pipelines/pipeline"
                            |> Layout.view
                            |> Query.fromHtml
                            |> Query.find [ id "top-bar-app" ]
                            |> Query.find [ tag "nav" ]
                            |> Query.find [ tag "ul" ]
                            |> Query.children []
                            |> Query.each
                                (Query.has [ style [ ( "display", "inline-block" ) ] ])
                , test "top bar has a square concourse logo on the left" <|
                    \_ ->
                        init "/teams/team/pipelines/pipeline"
                            |> Layout.view
                            |> Query.fromHtml
                            |> Query.find [ id "top-bar-app" ]
                            |> Query.children []
                            |> Query.first
                            |> Query.has
                                [ style
                                    [ ( "background-image", "url(/public/images/concourse_logo_white.svg)" )
                                    , ( "background-position", "50% 50%" )
                                    , ( "background-repeat", "no-repeat" )
                                    , ( "background-size", "42px 42px" )
                                    , ( "width", "54px" )
                                    , ( "height", "54px" )
                                    ]
                                ]
                , test "concourse logo on the left is a link to homepage" <|
                    \_ ->
                        init "/teams/team/pipelines/pipeline"
                            |> Layout.view
                            |> Query.fromHtml
                            |> Query.find [ id "top-bar-app" ]
                            |> Query.children []
                            |> Query.first
                            |> Query.has [ tag "a", attribute <| Attr.href "/" ]
                , test "top nav bar is blue when pipeline is paused" <|
                    \_ ->
                        init "/teams/team/pipelines/pipeline"
                            |> Layout.update
                                (Layout.TopMsg 1
                                    (TopBar.PipelineFetched
                                        (Ok
                                            { id = 0
                                            , name = "pipeline"
                                            , paused = True
                                            , public = True
                                            , teamName = "team"
                                            , groups = []
                                            }
                                        )
                                    )
                                )
                            |> Tuple.first
                            |> Layout.view
                            |> Query.fromHtml
                            |> Query.find [ id "top-bar-app" ]
                            |> Query.has
                                [ style
                                    [ ( "background-color", "#3498db" ) ]
                                ]
                , test "breadcrumb list is laid out horizontally" <|
                    \_ ->
                        init "/teams/team/pipelines/pipeline"
                            |> Layout.view
                            |> Query.fromHtml
                            |> Query.find [ id "top-bar-app" ]
                            |> Query.findAll [ tag "ul" ]
                            |> Query.first
                            |> Query.has [ style [ ( "display", "inline-block" ), ( "padding", "0 10px" ) ] ]
                , test "pipeline breadcrumb is laid out horizontally" <|
                    \_ ->
                        init "/teams/team/pipelines/pipeline"
                            |> Layout.view
                            |> Query.fromHtml
                            |> Query.find [ id "top-bar-app" ]
                            |> Query.find [ attribute <| Attr.href "/teams/team/pipelines/pipeline" ]
                            |> Query.has [ style [ ( "display", "inline-block" ) ] ]
                , test "top bar has pipeline breadcrumb with icon rendered first" <|
                    \_ ->
                        init "/teams/team/pipelines/pipeline"
                            |> Layout.view
                            |> Query.fromHtml
                            |> Query.find [ id "top-bar-app" ]
                            |> Query.find [ attribute <| Attr.href "/teams/team/pipelines/pipeline" ]
                            |> Query.children []
                            |> Query.first
                            |> Query.has pipelineBreadcrumbSelector
                , test "top bar has pipeline name after pipeline icon" <|
                    \_ ->
                        init "/teams/team/pipelines/pipeline"
                            |> Layout.view
                            |> Query.fromHtml
                            |> Query.find [ id "top-bar-app" ]
                            |> Query.find [ attribute <| Attr.href "/teams/team/pipelines/pipeline" ]
                            |> Query.children []
                            |> Query.index 1
                            |> Query.has
                                [ text "pipeline" ]
                , test "pipeline breadcrumb should have a link to the pipeline page on pipeline page" <|
                    \_ ->
                        init "/teams/team/pipelines/pipeline"
                            |> Layout.view
                            |> Query.fromHtml
                            |> Query.find [ id "top-bar-app" ]
                            |> Query.find [ tag "nav" ]
                            |> Query.children []
                            |> Query.index 1
                            |> Query.has [ tag "a", attribute <| Attr.href "/teams/team/pipelines/pipeline" ]
                , test "pipeline breadcrumb should have a link to the pipeline page when viewing build details" <|
                    \_ ->
                        init "/teams/team/pipelines/pipeline/jobs/build/builds/1"
                            |> Layout.view
                            |> Query.fromHtml
                            |> Query.find [ id "top-bar-app" ]
                            |> Query.find [ tag "nav" ]
                            |> Query.children []
                            |> Query.index 1
                            |> Query.has [ tag "a", attribute <| Attr.href "/teams/team/pipelines/pipeline" ]
                , test "pipeline breadcrumb should have a link to the pipeline page when viewing resource details" <|
                    \_ ->
                        init "/teams/team/pipelines/pipeline/resources/resource"
                            |> Layout.view
                            |> Query.fromHtml
                            |> Query.find [ id "top-bar-app" ]
                            |> Query.find [ tag "nav" ]
                            |> Query.children []
                            |> Query.index 1
                            |> Query.has [ tag "a", attribute <| Attr.href "/teams/team/pipelines/pipeline" ]
                , test "there should be a / between pipeline and job in breadcrumb" <|
                    \_ ->
                        init "/teams/team/pipelines/pipeline/jobs/build/builds/1"
                            |> Layout.view
                            |> Query.fromHtml
                            |> Query.find [ id "top-bar-app" ]
                            |> Query.find [ tag "nav" ]
                            |> Query.children []
                            |> Query.index 1
                            |> Query.has [ text "/" ]
                , test "job breadcrumb is laid out horizontally with appropriate spacing" <|
                    \_ ->
                        init "/teams/team/pipelines/pipeline/jobs/build/builds/1"
                            |> Layout.view
                            |> Query.fromHtml
                            |> Query.find [ id "top-bar-app" ]
                            |> Query.find [ tag "nav" ]
                            |> Query.find [ tag "ul" ]
                            |> Query.children []
                            |> Query.index 2
                            |> Query.has [ style [ ( "display", "inline-block" ), ( "padding", "0 10px" ) ] ]
                , test "top bar has job breadcrumb with job icon rendered first" <|
                    \_ ->
                        init "/teams/team/pipelines/pipeline/jobs/job/builds/1"
                            |> Layout.view
                            |> Query.fromHtml
                            |> Query.find [ id "top-bar-app" ]
                            |> Query.find [ tag "nav" ]
                            |> Query.find [ tag "ul" ]
                            |> Query.children []
                            |> Query.index 2
                            |> Query.has jobBreadcrumbSelector
                , test "top bar has build name after job icon" <|
                    \_ ->
                        init "/teams/team/pipelines/pipeline/jobs/job/builds/1"
                            |> Layout.view
                            |> Query.fromHtml
                            |> Query.find [ id "top-bar-app" ]
                            |> Query.find [ tag "nav" ]
                            |> Query.find [ tag "ul" ]
                            |> Query.children []
                            |> Query.index 2
                            |> Query.children []
                            |> Query.index 1
                            |> Query.has
                                [ text "job" ]
                , test "there should be a / between pipeline and resource in breadcrumb" <|
                    \_ ->
                        init "/teams/team/pipelines/pipeline/resources/resource"
                            |> Layout.view
                            |> Query.fromHtml
                            |> Query.find [ id "top-bar-app" ]
                            |> Query.find [ tag "nav" ]
                            |> Query.children []
                            |> Query.index 1
                            |> Query.has [ text "/" ]
                , test "resource breadcrumb is laid out horizontally with appropriate spacing" <|
                    \_ ->
                        init "/teams/team/pipelines/pipeline/resources/resource"
                            |> Layout.view
                            |> Query.fromHtml
                            |> Query.find [ id "top-bar-app" ]
                            |> Query.find [ tag "nav" ]
                            |> Query.find [ tag "ul" ]
                            |> Query.children []
                            |> Query.index 2
                            |> Query.has [ style [ ( "display", "inline-block" ), ( "padding", "0 10px" ) ] ]
                , test "top bar has resource breadcrumb with resource icon rendered first" <|
                    \_ ->
                        init "/teams/team/pipelines/pipeline/resources/resource"
                            |> Layout.view
                            |> Query.fromHtml
                            |> Query.find [ id "top-bar-app" ]
                            |> Query.find [ tag "nav" ]
                            |> Query.find [ tag "ul" ]
                            |> Query.children []
                            |> Query.index 2
                            |> Query.has resourceBreadcrumbSelector
                , test "top bar has resource name after resource icon" <|
                    \_ ->
                        init "/teams/team/pipelines/pipeline/resources/resource"
                            |> Layout.view
                            |> Query.fromHtml
                            |> Query.find [ id "top-bar-app" ]
                            |> Query.find [ tag "nav" ]
                            |> Query.find [ tag "ul" ]
                            |> Query.children []
                            |> Query.index 2
                            |> Query.children []
                            |> Query.index 1
                            |> Query.has
                                [ text "resource" ]
                ]
        ]


pipelineBreadcrumbSelector : List Selector
pipelineBreadcrumbSelector =
    [ style
        [ ( "background-image", "url(/public/images/ic_breadcrumb_pipeline.svg)" )
        , ( "background-repeat", "no-repeat" )
        ]
    ]


jobBreadcrumbSelector : List Selector
jobBreadcrumbSelector =
    [ style
        [ ( "background-image", "url(/public/images/ic_breadcrumb_job.svg)" )
        , ( "background-repeat", "no-repeat" )
        ]
    ]


resourceBreadcrumbSelector : List Selector
resourceBreadcrumbSelector =
    [ style
        [ ( "background-image", "url(/public/images/ic_breadcrumb_resource.svg)" )
        , ( "background-repeat", "no-repeat" )
        ]
    ]


init : String -> Layout.Model
init path =
    Layout.init
        { turbulenceImgSrc = ""
        , notFoundImgSrc = ""
        , csrfToken = ""
        }
        { href = ""
        , host = ""
        , hostname = ""
        , protocol = ""
        , origin = ""
        , port_ = ""
        , pathname = path
        , search = ""
        , hash = ""
        , username = ""
        , password = ""
        }
        |> Tuple.first
