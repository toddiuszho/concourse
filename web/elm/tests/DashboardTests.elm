module DashboardTests exposing (all)

import Concourse
import Dashboard
import Dashboard.APIData as APIData
import Dashboard.Msgs as Msgs
import Dict
import Expect exposing (Expectation)
import Dashboard.Group as Group
import Html.Attributes as Attr
import Html.Styled as HS
import RemoteData
import Test exposing (..)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector exposing (attribute, class, containing, style, tag, text, Selector)


lightGrey : String
lightGrey =
    "#3d3c3c"


all : Test
all =
    describe "Dashboard"
        [ test "links to specific builds" <|
            \_ ->
                whenOnDashboard { highDensity = False }
                    |> givenDataUnauthenticated givenPipelineWithJob
                    |> queryView
                    |> Query.find
                        [ class "dashboard-team-group"
                        , attribute <| Attr.attribute "data-team-name" "team"
                        ]
                    |> Query.find
                        [ class "node"
                        , attribute <| Attr.attribute "data-tooltip" "job"
                        ]
                    |> Query.find
                        [ tag "a" ]
                    |> Query.has
                        [ attribute <| Attr.href "/teams/team/pipelines/pipeline/jobs/job/builds/1" ]
        , test "shows team name with no pill when unauthenticated and team has an exposed pipeline" <|
            \_ ->
                whenOnDashboard { highDensity = False }
                    |> givenDataUnauthenticated (apiData [ ( "team", [ "pipeline" ] ) ])
                    |> queryView
                    |> teamHeaderHasNoPill "team"
        , test "shows OWNER pill on team header for team on which user has owner role" <|
            \_ ->
                whenOnDashboard { highDensity = False }
                    |> givenDataAndUser
                        (oneTeamOnePipeline "team")
                        (userWithRoles [ ( "team", [ "owner" ] ) ])
                    |> queryView
                    |> teamHeaderHasPill "team" "OWNER"
        , test "shows MEMBER pill on team header for team on which user has member role" <|
            \_ ->
                whenOnDashboard { highDensity = False }
                    |> givenDataAndUser
                        (oneTeamOnePipeline "team")
                        (userWithRoles [ ( "team", [ "member" ] ) ])
                    |> queryView
                    |> teamHeaderHasPill "team" "MEMBER"
        , test "shows VIEWER pill on team header for team on which user has viewer role" <|
            \_ ->
                whenOnDashboard { highDensity = False }
                    |> givenDataAndUser
                        (oneTeamOnePipeline "team")
                        (userWithRoles [ ( "team", [ "viewer" ] ) ])
                    |> queryView
                    |> teamHeaderHasPill "team" "VIEWER"
        , test "shows no pill on team header for team on which user has no role" <|
            \_ ->
                whenOnDashboard { highDensity = False }
                    |> givenDataAndUser
                        (oneTeamOnePipeline "team")
                        (userWithRoles [])
                    |> queryView
                    |> teamHeaderHasNoPill "team"
        , test "shows pill for first role on team header for team on which user has multiple roles" <|
            \_ ->
                whenOnDashboard { highDensity = False }
                    |> givenDataAndUser
                        (oneTeamOnePipeline "team")
                        (userWithRoles [ ( "team", [ "member", "viewer" ] ) ])
                    |> queryView
                    |> teamHeaderHasPill "team" "MEMBER"
        , test "sorts teams according to user role" <|
            \_ ->
                whenOnDashboard { highDensity = False }
                    |> givenDataAndUser
                        (apiData
                            [ ( "owner-team", [ "pipeline" ] )
                            , ( "nonmember-team", [] )
                            , ( "viewer-team", [] )
                            , ( "member-team", [] )
                            ]
                        )
                        (userWithRoles
                            [ ( "owner-team", [ "owner" ] )
                            , ( "member-team", [ "member" ] )
                            , ( "viewer-team", [ "viewer" ] )
                            , ( "nonmember-team", [] )
                            ]
                        )
                    |> queryView
                    |> Query.findAll teamHeaderSelector
                    |> Expect.all
                        [ Query.count (Expect.equal 4)
                        , Query.index 0 >> Query.has [ text "owner-team" ]
                        , Query.index 1 >> Query.has [ text "member-team" ]
                        , Query.index 2 >> Query.has [ text "viewer-team" ]
                        , Query.index 3 >> Query.has [ text "nonmember-team" ]
                        ]
        , test "team headers lay out contents horizontally, centering vertically" <|
            \_ ->
                whenOnDashboard { highDensity = False }
                    |> givenDataUnauthenticated (oneTeamOnePipeline "team")
                    |> queryView
                    |> Query.findAll teamHeaderSelector
                    |> Query.each
                        (Query.has
                            [ style
                                [ ( "display", "flex" )
                                , ( "align-items", "center" )
                                ]
                            ]
                        )
        , test "on HD view, there is space between the list of pipelines and the role pill" <|
            \_ ->
                whenOnDashboard { highDensity = True }
                    |> givenDataAndUser
                        (oneTeamOnePipeline "team")
                        (userWithRoles [ ( "team", [ "owner" ] ) ])
                    |> queryView
                    |> Query.find [ class "dashboard-team-name-wrapper" ]
                    |> Query.find [ containing [ text "OWNER" ] ]
                    |> Query.has [ style [ ( "margin-bottom", "1em" ) ] ]
        , test "on non-HD view, the role pill on a group has no margin below" <|
            \_ ->
                whenOnDashboard { highDensity = False }
                    |> givenDataAndUser
                        (oneTeamOnePipeline "team")
                        (userWithRoles [ ( "team", [ "owner" ] ) ])
                    |> queryView
                    |> Query.find teamHeaderSelector
                    |> Query.find [ containing [ text "OWNER" ] ]
                    |> Query.has [ style [ ( "margin-bottom", "" ) ] ]
        , describe "pipeline footer" <|
            let
                hasStyle : List ( String, String ) -> Expectation
                hasStyle styles =
                    whenOnDashboard { highDensity = False }
                        |> givenDataAndUser
                            (oneTeamOnePipeline "team")
                            (userWithRoles [ ( "team", [ "owner" ] ) ])
                        |> queryView
                        |> Query.find [ class "dashboard-pipeline-footer" ]
                        |> Query.has [ style styles ]
            in
                [ test "there is a light grey line dividing the footer from the rest of the card" <|
                    \_ ->
                        hasStyle [ ( "border-top", "2px solid " ++ lightGrey ) ]
                , test "has medium padding" <|
                    \_ ->
                        hasStyle [ ( "padding", "13.5px" ) ]
                , test "lays out contents horizontally" <|
                    \_ ->
                        hasStyle [ ( "display", "flex" ) ]
                , test "is divided into a left and right section, spread apart" <|
                    \_ ->
                        whenOnDashboard { highDensity = False }
                            |> givenDataAndUser
                                (oneTeamOnePipeline "team")
                                (userWithRoles [ ( "team", [ "owner" ] ) ])
                            |> queryView
                            |> Query.find [ class "dashboard-pipeline-footer" ]
                            |> Expect.all
                                [ Query.children []
                                    >> Query.count (Expect.equal 2)
                                , Query.has
                                    [ style [ ( "justify-content", "space-between" ) ] ]
                                ]
                , test "both sections lay out contents horizontally" <|
                    \_ ->
                        whenOnDashboard { highDensity = False }
                            |> givenDataAndUser
                                (oneTeamOnePipeline "team")
                                (userWithRoles [ ( "team", [ "owner" ] ) ])
                            |> queryView
                            |> Query.find [ class "dashboard-pipeline-footer" ]
                            |> Query.children []
                            |> Query.each (Query.has [ style [ ( "display", "flex" ) ] ])
                , test
                    ("there is a 20px square open eye icon on the far right for a public pipeline"
                        ++ " with image resized to fit"
                    )
                  <|
                    \_ ->
                        whenOnDashboard { highDensity = False }
                            |> givenDataAndUser
                                (oneTeamOnePipeline "team")
                                (userWithRoles [ ( "team", [ "owner" ] ) ])
                            |> queryView
                            |> Query.find [ class "dashboard-pipeline-footer" ]
                            |> Query.children []
                            |> Query.index -1
                            |> Query.children []
                            |> Query.index -1
                            |> Query.has
                                (iconSelector
                                    { size = "20px"
                                    , image = "baseline-visibility-24px.svg"
                                    }
                                    ++ [ style [ ( "background-size", "contain" ) ] ]
                                )
                , test
                    ("there is a 20px square slashed-out eye icon with on the far right for a"
                        ++ " non-public pipeline with image resized to fit"
                    )
                  <|
                    \_ ->
                        whenOnDashboard { highDensity = False }
                            |> givenDataAndUser
                                (oneTeamOnePipelineNonPublic "team")
                                (userWithRoles [ ( "team", [ "owner" ] ) ])
                            |> queryView
                            |> Query.find [ class "dashboard-pipeline-footer" ]
                            |> Query.children []
                            |> Query.index -1
                            |> Query.children []
                            |> Query.index -1
                            |> Query.has
                                (iconSelector
                                    { size = "20px"
                                    , image = "baseline-visibility_off-24px.svg"
                                    }
                                    ++ [ style [ ( "background-size", "contain" ) ] ]
                                )
                , test "there is medium spacing between the eye and the play/pause button" <|
                    \_ ->
                        whenOnDashboard { highDensity = False }
                            |> givenDataAndUser
                                (oneTeamOnePipeline "team")
                                (userWithRoles [ ( "team", [ "owner" ] ) ])
                            |> queryView
                            |> Query.find [ class "dashboard-pipeline-footer" ]
                            |> Query.children []
                            |> Query.index -1
                            |> Query.children []
                            |> Expect.all
                                [ Query.count (Expect.equal 3)
                                , Query.index 1 >> Query.has [ style [ ( "width", "13.5px" ) ] ]
                                ]
                , test "the right section has a 20px square pause button on the left" <|
                    \_ ->
                        whenOnDashboard { highDensity = False }
                            |> givenDataAndUser
                                (oneTeamOnePipeline "team")
                                (userWithRoles [ ( "team", [ "owner" ] ) ])
                            |> queryView
                            |> Query.find [ class "dashboard-pipeline-footer" ]
                            |> Query.children []
                            |> Query.index -1
                            |> Query.children []
                            |> Query.index 0
                            |> Query.has
                                (iconSelector
                                    { size = "20px"
                                    , image = "ic_pause_white.svg"
                                    }
                                )
                , test "pause button has pointer cursor" <|
                    \_ ->
                        whenOnDashboard { highDensity = False }
                            |> givenDataAndUser
                                (oneTeamOnePipeline "team")
                                (userWithRoles [ ( "team", [ "owner" ] ) ])
                            |> queryView
                            |> Query.find [ class "dashboard-pipeline-footer" ]
                            |> Query.find
                                (iconSelector
                                    { size = "20px"
                                    , image = "ic_pause_white.svg"
                                    }
                                )
                            |> Query.has [ style [ ( "cursor", "pointer" ) ] ]
                , test "pause button is transparent" <|
                    \_ ->
                        whenOnDashboard { highDensity = False }
                            |> givenDataAndUser
                                (oneTeamOnePipeline "team")
                                (userWithRoles [ ( "team", [ "owner" ] ) ])
                            |> queryView
                            |> Query.find [ class "dashboard-pipeline-footer" ]
                            |> Query.find
                                (iconSelector
                                    { size = "20px"
                                    , image = "ic_pause_white.svg"
                                    }
                                )
                            |> Query.has [ style [ ( "opacity", "0.5" ) ] ]
                , defineHoverBehaviour
                    { name = "pause button"
                    , setup =
                        whenOnDashboard { highDensity = False }
                            |> givenDataAndUser
                                (oneTeamOnePipeline "team")
                                (userWithRoles [ ( "team", [ "owner" ] ) ])
                    , query =
                        Dashboard.view
                            >> HS.toUnstyled
                            >> Query.fromHtml
                            >> Query.find [ class "dashboard-pipeline-footer" ]
                            >> Query.children []
                            >> Query.index -1
                            >> Query.children []
                            >> Query.index 0
                    , unhoveredSelector =
                        { description = "a transparent 20px square pause button with pointer cursor"
                        , selector =
                            (iconSelector
                                { size = "20px"
                                , image = "ic_pause_white.svg"
                                }
                                ++ [ style
                                        [ ( "cursor", "pointer" )
                                        , ( "opacity", "0.5" )
                                        ]
                                   ]
                            )
                        }
                    , mouseEnterMsg = Msgs.PipelineButtonHover <| Just <| onePipeline "team"
                    , mouseLeaveMsg = Msgs.PipelineButtonHover Nothing
                    , hoveredSelector =
                        { description = "an opaque 20px square pause button with pointer cursor"
                        , selector =
                            (iconSelector
                                { size = "20px"
                                , image = "ic_pause_white.svg"
                                }
                                ++ [ style
                                        [ ( "cursor", "pointer" )
                                        , ( "opacity", "1" )
                                        ]
                                   ]
                            )
                        }
                    }
                , defineHoverBehaviour
                    { name = "play button"
                    , setup =
                        whenOnDashboard { highDensity = False }
                            |> givenDataAndUser
                                (oneTeamOnePipelinePaused "team")
                                (userWithRoles [ ( "team", [ "owner" ] ) ])
                    , query =
                        Dashboard.view
                            >> HS.toUnstyled
                            >> Query.fromHtml
                            >> Query.find [ class "dashboard-pipeline-footer" ]
                            >> Query.children []
                            >> Query.index -1
                            >> Query.children []
                            >> Query.index 0
                    , unhoveredSelector =
                        { description = "a transparent 20px square play button with pointer cursor"
                        , selector =
                            (iconSelector
                                { size = "20px"
                                , image = "ic_play_white.svg"
                                }
                                ++ [ style
                                        [ ( "cursor", "pointer" )
                                        , ( "opacity", "0.5" )
                                        ]
                                   ]
                            )
                        }
                    , mouseEnterMsg = Msgs.PipelineButtonHover <| Just <| onePipelinePaused "team"
                    , mouseLeaveMsg = Msgs.PipelineButtonHover Nothing
                    , hoveredSelector =
                        { description = "an opaque 20px square play button with pointer cursor"
                        , selector =
                            (iconSelector
                                { size = "20px"
                                , image = "ic_play_white.svg"
                                }
                                ++ [ style
                                        [ ( "cursor", "pointer" )
                                        , ( "opacity", "1" )
                                        ]
                                   ]
                            )
                        }
                    }
                ]
        ]


defineHoverBehaviour :
    { name : String
    , setup : Dashboard.Model
    , query : Dashboard.Model -> Query.Single Msgs.Msg
    , unhoveredSelector : { description : String, selector : List Selector }
    , mouseEnterMsg : Msgs.Msg
    , mouseLeaveMsg : Msgs.Msg
    , hoveredSelector : { description : String, selector : List Selector }
    }
    -> Test
defineHoverBehaviour { name, setup, query, unhoveredSelector, mouseEnterMsg, mouseLeaveMsg, hoveredSelector } =
    describe (name ++ " hover behaviour")
        [ test (name ++ " is " ++ unhoveredSelector.description) <|
            \_ ->
                setup
                    |> query
                    |> Query.has unhoveredSelector.selector
        , test ("mousing over " ++ name ++ " triggers " ++ toString mouseEnterMsg ++ " msg") <|
            \_ ->
                setup
                    |> query
                    |> Event.simulate Event.mouseEnter
                    |> Event.expect mouseEnterMsg
        , test
            (toString mouseEnterMsg
                ++ " msg causes "
                ++ name
                ++ " to become "
                ++ hoveredSelector.description
            )
          <|
            \_ ->
                setup
                    |> Dashboard.update mouseEnterMsg
                    |> Tuple.first
                    |> query
                    |> Query.has hoveredSelector.selector
        , test ("mousing off " ++ name ++ " triggers " ++ toString mouseLeaveMsg ++ " msg") <|
            \_ ->
                setup
                    |> Dashboard.update mouseEnterMsg
                    |> Tuple.first
                    |> query
                    |> Event.simulate Event.mouseLeave
                    |> Event.expect mouseLeaveMsg
        , test
            (toString mouseLeaveMsg
                ++ " msg causes "
                ++ name
                ++ " to become "
                ++ unhoveredSelector.description
            )
          <|
            \_ ->
                setup
                    |> Dashboard.update mouseEnterMsg
                    |> Tuple.first
                    |> Dashboard.update mouseLeaveMsg
                    |> Tuple.first
                    |> query
                    |> Query.has unhoveredSelector.selector
        ]


iconSelector : { size : String, image : String } -> List Selector
iconSelector { size, image } =
    [ style
        [ ( "background-image", "url(public/images/" ++ image ++ ")" )
        , ( "background-position", "50% 50%" )
        , ( "background-repeat", "no-repeat" )
        , ( "width", size )
        , ( "height", size )
        ]
    ]


whenOnDashboard : { highDensity : Bool } -> Dashboard.Model
whenOnDashboard { highDensity } =
    Dashboard.init
        { title = always Cmd.none
        }
        { csrfToken = ""
        , turbulencePath = ""
        , search = ""
        , highDensity = highDensity
        }
        |> Tuple.first


queryView : Dashboard.Model -> Query.Single Msgs.Msg
queryView =
    Dashboard.view
        >> HS.toUnstyled
        >> Query.fromHtml


givenDataAndUser : APIData.APIData -> Concourse.User -> Dashboard.Model -> Dashboard.Model
givenDataAndUser data user =
    Dashboard.update
        (Msgs.APIDataFetched <|
            RemoteData.Success ( 0, ( data, Just user ) )
        )
        >> Tuple.first


userWithRoles : List ( String, List String ) -> Concourse.User
userWithRoles roles =
    { id = "0"
    , userName = "test"
    , name = "test"
    , email = "test"
    , teams =
        Dict.fromList roles
    }


givenDataUnauthenticated : APIData.APIData -> Dashboard.Model -> Dashboard.Model
givenDataUnauthenticated data =
    Dashboard.update
        (Msgs.APIDataFetched <|
            RemoteData.Success ( 0, ( data, Nothing ) )
        )
        >> Tuple.first


givenPipelineWithJob : APIData.APIData
givenPipelineWithJob =
    { teams = []
    , pipelines =
        [ { id = 0
          , name = "pipeline"
          , paused = False
          , public = True
          , teamName = "team"
          , groups = []
          }
        ]
    , jobs =
        [ { pipeline =
                { teamName = "team"
                , pipelineName = "pipeline"
                }
          , name = "job"
          , pipelineName = "pipeline"
          , teamName = "team"
          , nextBuild = Nothing
          , finishedBuild =
                Just
                    { id = 0
                    , name = "1"
                    , job = Just { teamName = "team", pipelineName = "pipeline", jobName = "job" }
                    , status = Concourse.BuildStatusSucceeded
                    , duration = { startedAt = Nothing, finishedAt = Nothing }
                    , reapTime = Nothing
                    }
          , transitionBuild = Nothing
          , paused = False
          , disableManualTrigger = False
          , inputs = []
          , outputs = []
          , groups = []
          }
        ]
    , resources = []
    , version = ""
    }


oneTeamOnePipelinePaused : String -> APIData.APIData
oneTeamOnePipelinePaused teamName =
    { teams = [ { id = 0, name = teamName } ]
    , pipelines =
        [ { id = 0
          , name = "pipeline"
          , paused = True
          , public = True
          , teamName = teamName
          , groups = []
          }
        ]
    , jobs = []
    , resources = []
    , version = ""
    }


oneTeamOnePipelineNonPublic : String -> APIData.APIData
oneTeamOnePipelineNonPublic teamName =
    { teams = [ { id = 0, name = teamName } ]
    , pipelines =
        [ { id = 0
          , name = "pipeline"
          , paused = False
          , public = False
          , teamName = teamName
          , groups = []
          }
        ]
    , jobs = []
    , resources = []
    , version = ""
    }


oneTeamOnePipeline : String -> APIData.APIData
oneTeamOnePipeline teamName =
    apiData [ ( teamName, [ "pipeline" ] ) ]


onePipeline : String -> Concourse.Pipeline
onePipeline teamName =
    { id = 0
    , name = "pipeline"
    , paused = False
    , public = True
    , teamName = teamName
    , groups = []
    }


onePipelinePaused : String -> Concourse.Pipeline
onePipelinePaused teamName =
    { id = 0
    , name = "pipeline"
    , paused = True
    , public = True
    , teamName = teamName
    , groups = []
    }


apiData : List ( String, List String ) -> APIData.APIData
apiData pipelines =
    { teams = pipelines |> List.map Tuple.first |> List.indexedMap Concourse.Team
    , pipelines =
        pipelines
            |> List.concatMap
                (\( teamName, ps ) ->
                    ps
                        |> List.indexedMap
                            (\i p ->
                                { id = i
                                , name = p
                                , paused = False
                                , public = True
                                , teamName = teamName
                                , groups = []
                                }
                            )
                )
    , jobs = []
    , resources = []
    , version = ""
    }


teamHeaderSelector : List Selector
teamHeaderSelector =
    [ class <| .sectionHeaderClass Group.stickyHeaderConfig ]


teamHeaderHasNoPill : String -> Query.Single Msgs.Msg -> Expectation
teamHeaderHasNoPill teamName =
    Query.find (teamHeaderSelector ++ [ containing [ text teamName ] ])
        >> Query.children []
        >> Query.count (Expect.equal 1)


teamHeaderHasPill : String -> String -> Query.Single Msgs.Msg -> Expectation
teamHeaderHasPill teamName pillText =
    Query.find (teamHeaderSelector ++ [ containing [ text teamName ] ])
        >> Query.children []
        >> Expect.all
            [ Query.count (Expect.equal 2)
            , Query.index 1 >> Query.has [ text pillText ]
            ]
