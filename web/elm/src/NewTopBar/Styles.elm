module NewTopBar.Styles exposing (..)

import Css exposing (..)
import MobileState exposing (MobileState(..))
import ScreenSize exposing (ScreenSize(..))


topBar : List Style
topBar =
    [ position fixed
    , top zero
    , width (pct 100)
    , zIndex (int 999)
    , displayFlex
    , backgroundColor (hex "1e1d1d")
    ]


concourseLogo : List Style
concourseLogo =
    [ backgroundImage (url "public/images/concourse_logo_white.svg")
    , backgroundSize2 (px 42) (px 42)
    , backgroundPosition center
    , backgroundRepeat noRepeat
    , display inlineBlock
    , height (px 54)
    , width (px 54)
    ]


searchBar : { a | screenSize : ScreenSize, mobileSearchState : MobileState } -> List Style
searchBar { screenSize, mobileSearchState } =
    ([ displayFlex
     , flexDirection column
     , flexGrow (num 1)
     , justifyContent center
     , padding (px 12)
     , position relative
     ]
        ++ (case screenSize of
                Desktop ->
                    [ alignItems center ]

                Mobile ->
                    case mobileSearchState of
                        Expanded ->
                            [ alignItems stretch ]

                        Collapsed ->
                            [ alignItems flexStart ]
           )
    )


searchInput : ScreenSize -> List Style
searchInput screenSize =
    ([ backgroundColor transparent
     , backgroundImage (url "public/images/ic_search_white_24px.svg")
     , backgroundRepeat noRepeat
     , backgroundPosition2 (px 12) (px 8)
     , border3 (px 1) solid (hex "504b4b")
     , color (hex "fff")
     , fontSize (em 1.15)
     , fontFamilies [ "Inconsolata", .value monospace ]
     , height (px 30)
     , padding2 zero (px 42)
     , focus
        [ border3 (px 1) solid (hex "504b4b")
        , outline zero
        ]
     ]
        ++ (case screenSize of
                Desktop ->
                    [ width (px 220) ]

                Mobile ->
                    []
           )
    )


searchOptionsList : List Style
searchOptionsList =
    [ position absolute
    , top (px 32)
    ]


searchOption : { screenSize : ScreenSize, active : Bool } -> List Style
searchOption { screenSize, active } =
    let
        widthStyles =
            case screenSize of
                Desktop ->
                    [ width (px 220) ]

                Mobile ->
                    []

        activeStyles =
            if active then
                [ backgroundColor (hex "1e1d1d")
                , color (hex "fff")
                ]
            else
                []

        layout =
            [ marginTop (px -1)
            , border3 (px 1) solid (hex "504b4b")
            , textAlign left
            , lineHeight (px 30)
            , padding2 zero (px 42)
            ]

        styling =
            [ listStyleType none
            , backgroundColor (hex "2e2e2e")
            , fontSize (em 1.15)
            , cursor pointer
            , color (hex "9b9b9b")
            ]
    in
        layout ++ styling ++ widthStyles ++ activeStyles


searchButton : List Style
searchButton =
    [ backgroundImage (url "public/images/ic_search_white_24px.svg")
    , backgroundRepeat noRepeat
    , backgroundPosition2 (px 13) (px 9)
    , height (px 32)
    , width (px 32)
    , display inlineBlock
    , float left
    ]


userInfo : List Style
userInfo =
    [ overflow hidden
    , textOverflow ellipsis
    , padding2 zero (px 30)
    , borderLeft3 (px 1) solid (hex "3d3c3c")
    , displayFlex
    , alignItems center
    , justifyContent center
    ]
