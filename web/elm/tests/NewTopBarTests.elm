module NewTopBarTests exposing (all, init, queryView, smallScreen, updateModel)

import Dict
import Expect
import Html.Attributes as Attributes
import Html.Styled as HS
import NewTopBar
import RemoteData
import Test exposing (..)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector as THS exposing (attribute, containing, id, tag, text)


init : { highDensity : Bool, query : String } -> NewTopBar.Model
init { highDensity, query } =
    NewTopBar.init (not highDensity) query
        |> Tuple.first


smallScreen : NewTopBar.Model -> NewTopBar.Model
smallScreen =
    updateModel <|
        NewTopBar.ScreenResized { width = 300, height = 800 }


queryView : NewTopBar.Model -> Query.Single NewTopBar.Msg
queryView =
    NewTopBar.view
        >> HS.toUnstyled
        >> Query.fromHtml


updateModel : NewTopBar.Msg -> NewTopBar.Model -> NewTopBar.Model
updateModel msg =
    NewTopBar.update msg >> Tuple.first


all : Test
all =
    describe "NewTopBarSearchInput"
        [ describe "autocompletion"
            [ test "initially status and team" <|
                \_ ->
                    init { highDensity = False, query = "" }
                        |> updateModel NewTopBar.FocusMsg
                        |> queryView
                        |> Query.findAll [ tag "li" ]
                        |> Expect.all
                            [ Query.count (Expect.equal 2)
                            , Query.index 0
                                >> Query.has [ text "status:" ]
                            , Query.index 1
                                >> Query.has [ text "team:" ]
                            ]
            ]
        , describe "on small screens"
            [ test "shows the search icon" <|
                \_ ->
                    init { highDensity = False, query = "" }
                        |> smallScreen
                        |> queryView
                        |> Query.findAll [ id "search-btn" ]
                        |> Query.count (Expect.equal 1)
            , test "shows no search bar on high density" <|
                \_ ->
                    init { highDensity = True, query = "" }
                        |> updateModel
                            (NewTopBar.ScreenResized
                                { width = 300, height = 800 }
                            )
                        |> queryView
                        |> Query.findAll [ tag "input" ]
                        |> Query.count (Expect.equal 0)
            , describe "when logged in"
                [ test "shows the user's name" <|
                    \_ ->
                        init { highDensity = False, query = "" }
                            |> smallScreen
                            |> updateModel
                                (NewTopBar.UserFetched
                                    (RemoteData.Success
                                        { id = "some-user"
                                        , userName = "some-user"
                                        , name = "some-user"
                                        , email = "some-user"
                                        , teams = Dict.empty
                                        }
                                    )
                                )
                            |> queryView
                            |> Query.has [ text "some-user" ]
                , test "does not show logout button" <|
                    \_ ->
                        init { highDensity = False, query = "" }
                            |> smallScreen
                            |> updateModel
                                (NewTopBar.UserFetched
                                    (RemoteData.Success
                                        { id = "some-user"
                                        , userName = "some-user"
                                        , name = "some-user"
                                        , email = "some-user"
                                        , teams = Dict.empty
                                        }
                                    )
                                )
                            |> queryView
                            |> Query.findAll [ text "logout" ]
                            |> Query.count (Expect.equal 0)
                , test "clicking username sends ToggleUserMenu message" <|
                    \_ ->
                        init { highDensity = False, query = "" }
                            |> smallScreen
                            |> updateModel
                                (NewTopBar.UserFetched
                                    (RemoteData.Success
                                        { id = "some-user"
                                        , userName = "some-user"
                                        , name = "some-user"
                                        , email = "some-user"
                                        , teams = Dict.empty
                                        }
                                    )
                                )
                            |> queryView
                            |> Query.find [ id "user-id", containing [ text "some-user" ] ]
                            |> Event.simulate Event.click
                            |> Event.expect NewTopBar.ToggleUserMenu
                , test "ToggleUserMenu message shows logout button" <|
                    \_ ->
                        init { highDensity = False, query = "" }
                            |> smallScreen
                            |> updateModel
                                (NewTopBar.UserFetched
                                    (RemoteData.Success
                                        { id = "some-user"
                                        , userName = "some-user"
                                        , name = "some-user"
                                        , email = "some-user"
                                        , teams = Dict.empty
                                        }
                                    )
                                )
                            |> updateModel NewTopBar.ToggleUserMenu
                            |> queryView
                            |> Query.findAll [ text "logout" ]
                            |> Query.count (Expect.equal 1)
                ]
            , test "shows no search input" <|
                \_ ->
                    init { highDensity = False, query = "" }
                        |> smallScreen
                        |> queryView
                        |> Query.findAll [ tag "input" ]
                        |> Query.count (Expect.equal 0)
            , test "shows search input when resizing" <|
                \_ ->
                    init { highDensity = False, query = "" }
                        |> smallScreen
                        |> updateModel
                            (NewTopBar.ScreenResized
                                { width = 1200, height = 900 }
                            )
                        |> queryView
                        |> Query.findAll [ tag "input" ]
                        |> Query.count (Expect.equal 1)
            , test "sends a ShowSearchInput message when the search button is clicked" <|
                \_ ->
                    init { highDensity = False, query = "" }
                        |> smallScreen
                        |> queryView
                        |> Query.find [ id "search-btn" ]
                        |> Event.simulate Event.click
                        |> Event.expect NewTopBar.ShowSearchInput
            , describe "on ShowSearchInput"
                [ test "hides the search button" <|
                    \_ ->
                        init { highDensity = False, query = "" }
                            |> smallScreen
                            |> updateModel NewTopBar.ShowSearchInput
                            |> queryView
                            |> Query.findAll [ id "search-btn" ]
                            |> Query.count (Expect.equal 0)
                , test "shows the search bar" <|
                    \_ ->
                        init { highDensity = False, query = "" }
                            |> smallScreen
                            |> updateModel NewTopBar.ShowSearchInput
                            |> queryView
                            |> Query.findAll [ tag "input" ]
                            |> Query.count (Expect.equal 1)
                , test "hides the user info/logout button" <|
                    \_ ->
                        init { highDensity = False, query = "" }
                            |> smallScreen
                            |> updateModel NewTopBar.ShowSearchInput
                            |> updateModel
                                (NewTopBar.UserFetched
                                    (RemoteData.Success
                                        { id = "some-user"
                                        , userName = "some-user"
                                        , name = "some-user"
                                        , email = "some-user"
                                        , teams = Dict.empty
                                        }
                                    )
                                )
                            |> queryView
                            |> Query.findAll [ text "some-user" ]
                            |> Query.count (Expect.equal 0)
                , test "sends a BlurMsg message when the search input is blurred" <|
                    \_ ->
                        init { highDensity = False, query = "" }
                            |> smallScreen
                            |> updateModel NewTopBar.ShowSearchInput
                            |> queryView
                            |> Query.find [ tag "input" ]
                            |> Event.simulate Event.blur
                            |> Event.expect NewTopBar.BlurMsg
                ]
            , describe "on BlurMsg"
                [ test "hides the search bar when there is no query" <|
                    \_ ->
                        init { highDensity = False, query = "" }
                            |> smallScreen
                            |> updateModel NewTopBar.ShowSearchInput
                            |> updateModel NewTopBar.BlurMsg
                            |> queryView
                            |> Query.findAll [ tag "input" ]
                            |> Query.count (Expect.equal 0)
                , test "hides the autocomplete when there is a query" <|
                    \_ ->
                        init { highDensity = False, query = "" }
                            |> smallScreen
                            |> updateModel NewTopBar.ShowSearchInput
                            |> updateModel (NewTopBar.FilterMsg "status:")
                            |> updateModel NewTopBar.BlurMsg
                            |> queryView
                            |> Expect.all
                                [ Query.findAll [ tag "input" ]
                                    >> Query.count (Expect.equal 1)
                                , Query.findAll [ tag "ul" ]
                                    >> Query.count (Expect.equal 0)
                                ]
                , test "shows the search button" <|
                    \_ ->
                        init { highDensity = False, query = "" }
                            |> smallScreen
                            |> updateModel NewTopBar.ShowSearchInput
                            |> updateModel NewTopBar.BlurMsg
                            |> queryView
                            |> Query.findAll [ id "search-btn" ]
                            |> Query.count (Expect.equal 1)
                , test "shows the user info/logout button" <|
                    \_ ->
                        init { highDensity = False, query = "" }
                            |> smallScreen
                            |> updateModel NewTopBar.ShowSearchInput
                            |> updateModel NewTopBar.BlurMsg
                            |> updateModel
                                (NewTopBar.UserFetched
                                    (RemoteData.Success
                                        { id = "some-user"
                                        , userName = "some-user"
                                        , name = "some-user"
                                        , email = "some-user"
                                        , teams = Dict.empty
                                        }
                                    )
                                )
                            |> queryView
                            |> Query.has [ text "some-user" ]
                ]
            , describe "starting with a query"
                [ test "shows the search input on small screens" <|
                    \_ ->
                        init { highDensity = False, query = "some-query" }
                            |> updateModel
                                (NewTopBar.ScreenResized
                                    { width = 300, height = 800 }
                                )
                            |> queryView
                            |> Query.findAll [ tag "input" ]
                            |> Query.count (Expect.equal 1)
                ]
            ]
        , describe "on large screens"
            [ test "shows the entire search input on large screens" <|
                \_ ->
                    init { highDensity = False, query = "" }
                        |> updateModel
                            (NewTopBar.ScreenResized
                                { width = 1200, height = 900 }
                            )
                        |> queryView
                        |> Query.find [ tag "input" ]
                        |> Query.has [ attribute (Attributes.placeholder "search") ]
            , test "hides the search input on changing to a small screen" <|
                \_ ->
                    init { highDensity = False, query = "" }
                        |> updateModel
                            (NewTopBar.ScreenResized
                                { width = 1200, height = 900 }
                            )
                        |> updateModel
                            (NewTopBar.ScreenResized
                                { width = 300, height = 800 }
                            )
                        |> queryView
                        |> Query.findAll [ tag "input" ]
                        |> Query.count (Expect.equal 0)
            , test "shows no search bar on high density" <|
                \_ ->
                    init { highDensity = True, query = "" }
                        |> updateModel
                            (NewTopBar.ScreenResized
                                { width = 1200, height = 900 }
                            )
                        |> queryView
                        |> Query.findAll [ tag "input" ]
                        |> Query.count (Expect.equal 0)
            ]
        ]
