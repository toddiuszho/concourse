module NewTopBarTests exposing (..)

import Dict
import Expect
import Html.Attributes as Attributes
import Html.Styled as HS
import Test exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector as THS exposing (tag, attribute, class, text)
import Test.Html.Event as Event
import NewTopBar
import RemoteData
import ScreenSize exposing (ScreenSize(..))


smallScreen : NewTopBar.Model
smallScreen =
    let
        model =
            Tuple.first (NewTopBar.init True "")
    in
        { model | screenSize = Mobile }


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
        [ describe "on small screens"
            [ test "shows the search icon"
                (\_ ->
                    smallScreen
                        |> queryView
                        |> Query.findAll [ class "search-btn" ]
                        |> Query.count (Expect.equal 1)
                )
            , test "shows the user info/logout button"
                (\_ ->
                    smallScreen
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
                )
            , test "shows no search input"
                (\_ ->
                    smallScreen
                        |> queryView
                        |> Query.findAll [ tag "input" ]
                        |> Query.count (Expect.equal 0)
                )
            , test "sends a ShowSearchInput message when the search button is clicked"
                (\_ ->
                    smallScreen
                        |> queryView
                        |> Query.find [ class "search-btn" ]
                        |> Event.simulate Event.click
                        |> Event.expect NewTopBar.ShowSearchInput
                )
            , describe "on ShowSearchInput"
                [ test "hides the search button"
                    (\_ ->
                        smallScreen
                            |> updateModel NewTopBar.ShowSearchInput
                            |> queryView
                            |> Query.findAll [ class "search-btn" ]
                            |> Query.count (Expect.equal 0)
                    )
                , test "shows the search bar"
                    (\_ ->
                        smallScreen
                            |> updateModel NewTopBar.ShowSearchInput
                            |> queryView
                            |> Query.findAll [ tag "input" ]
                            |> Query.count (Expect.equal 1)
                    )
                , test "hides the user info/logout button"
                    (\_ ->
                        smallScreen
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
                    )
                , test "sends a BlurMsg message when the search input is blurred"
                    (\_ ->
                        smallScreen
                            |> updateModel NewTopBar.ShowSearchInput
                            |> queryView
                            |> Query.find [ tag "input" ]
                            |> Event.simulate Event.blur
                            |> Event.expect NewTopBar.BlurMsg
                    )
                ]
            , describe "on BlurMsg"
                [ test "hides the search bar"
                    (\_ ->
                        smallScreen
                            |> updateModel NewTopBar.ShowSearchInput
                            |> updateModel NewTopBar.BlurMsg
                            |> queryView
                            |> Query.findAll [ tag "input" ]
                            |> Query.count (Expect.equal 0)
                    )
                , test "shows the search button"
                    (\_ ->
                        smallScreen
                            |> updateModel NewTopBar.ShowSearchInput
                            |> updateModel NewTopBar.BlurMsg
                            |> queryView
                            |> Query.findAll [ class "search-btn" ]
                            |> Query.count (Expect.equal 1)
                    )
                , test "shows the user info/logout button"
                    (\_ ->
                        smallScreen
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
                    )
                ]
            , describe "on FilterMsg -- this is a bullshit testcase"
                [ test "shows the search bar"
                    (\_ ->
                        smallScreen
                            |> updateModel NewTopBar.ShowSearchInput
                            |> updateModel NewTopBar.BlurMsg
                            |> queryView
                            |> Query.findAll [ tag "input" ]
                            |> Query.count (Expect.equal 1)
                    )
                ]
            ]
        , describe "on large screens"
            [ test "shows the entire search input on large screens"
                (\_ ->
                    NewTopBar.init True ""
                        |> Tuple.first
                        |> queryView
                        |> Query.find [ tag "input" ]
                        |> Query.has [ attribute (Attributes.placeholder "search") ]
                )
            , test "hides the search input on changing to a small screen"
                (\_ ->
                    NewTopBar.init True ""
                        |> Tuple.first
                        |> updateModel (NewTopBar.ScreenResized { width = 300, height = 800 })
                        |> queryView
                        |> Query.findAll [ tag "input" ]
                        |> Query.count (Expect.equal 0)
                )
            ]
        ]
