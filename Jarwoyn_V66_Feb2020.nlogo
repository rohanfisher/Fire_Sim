extensions [gis palette vid]
breed [fires fire] ;; bright red turtles -- the leading edge of the fire
breed [embers ember] ;; turtles gradually fading from red to near black
breed [ashes ash]
breed [smoke smok] smoke-own [smoke-life]
breed [spinners spinner ]
breed [dots dot]
globals [view autoburn burnday today tslb-dataset  dem-dataset
    veg-dataset wetness-dataset burnt2017-dataset burnt2018-dataset  cliff-dataset DOY-dataset dayofmonth dayofyear date
    burnt-area
    border land
    randburn
    night timeofday tod iteration timeod int-fire-danger exploded int-ws
  tempcolor
  wsv cws windran wd wd-1 wd-2 wd-3 wd-4 wd-5 wd-6 wd-7 direction ember-fly-dist ember-rand hotspots monthname]

patches-own
[ab burntab
  Wetness
  elevation
  burnt
  veg
  tslb
  slope
  wind
  burnablity
  burnprob
  burnttime
  fuelload
  topowet
  HotSpot_Burn
  SAVED-IGNITION out1 totalout]


to setup
  __clear-all-and-reset-ticks
  set-default-shape turtles "circle"
  set view "Hill Shade"
  set night night = 0
  set ember-fly-dist 0
  set-time-of-day
  ask patches [set wind 1]
  ask patches [set burnttime 1]
  set border patches with [ count neighbors != 8 ]
  setup-patches
  set land patches with [ elevation > 1 ]
  ask patches [set-fuelload]
  clear
end

to clear
  clear-turtles
  reset-ticks
;  set-time-of-day
  ask patches [set burnt 100]
  ask patches [set burnttime 1]
  view-new
end

to go
    set night (ticks / 300) ;; Need To Change With Difference Spatial Resolution
    if  time-of-day [changeFire_Danger]
    if Stop-if-no-fire and not any? embers and not any? fires [stop]
    ask border   [  ask turtles-here [ die ]  ]
    ask turtles  [calc-slope]
    ask turtles [calc-windinfluence]
    if ticks = 0 [set-windspeed ask patches [set-topowet] ]
    check-spread
    set burnt-area ((count patches with [burnt = 0]) * 0.0064) ;; Need To Change With Difference Spatial Resolution
    fade-embers
    set tod tod + 1
    ;;if not any? turtles [save-iter]
    change-wind-speed
    tick
    if vid:recorder-status = "recording" [ vid:record-view ]
     ask spinners with [size > 59] [ set heading  (tod * 2.4 + 150)]
  if exploded = 1 [ ask patches with [SAVED-IGNITION = 50] [explode] ]
    update-labels
    move-smoke
end

;***********************************SET FIRE WEATHER***********************************
to set-fire-weather
set int-fire-danger fire_danger
set int-ws wsv
show-labels
set-windspeed
set-time-of-day
ask patches [if TSLB = 0 [set fuelload (-0.15 * Fire_Danger + 1.75)]]

end

;***************************************************************************************
;***********************************CHECK FIRE SPREAD***********************************
;***************************************************************************************

to check-spread
    ask fires  ;;determines intial spread make probability lower to simultate rapid fire spred only under high burn conditions.
     [ set randburn (random-float 60) ;22
          ask neighbors [ set burnablity  (fuelload * (((-0.039 * (Fire_Danger ^ 2)) + (Fire_Danger * 0.8) - 0.7)  * (topowet)))]
          ask neighbors [ set burnprob ((burnablity * (wind * slope)))]
          ask neighbors with [randburn < burnprob and burnt = 100 ][ignite]
        let emberfly patch-at-heading-and-distance direction ember-fly-dist
        if emberfly != nobody  [ask emberfly [if burnt = 100 [ignite]]]
        set breed embers
        make-smoke ]
ask embers
        [ set randburn (random-float 50) ;23
          ask neighbors with [ ((randburn + (burnttime * 2)) < (burnprob)) and burnt = 100 ][let ransnd random 20 ignite]] ;2.5
end

;***************************************************************************************
;*************************************    IGNITION   ***********************************
;***************************************************************************************
to make-smoke
  if (cws = 1)
      [ask patch-here [sprout-smoke 1 [set smoke-life random 400 set size 4 set color [200 200 200 20]]] ]
  if (cws = 2)
     [ let smoke-appear patch-at-heading-and-distance direction  random 3
        if smoke-appear != nobody [ask smoke-appear [sprout-smoke 1 [set smoke-life random 200 set size 3 set heading direction set color [200 200 200 40]]] ]]
  if (cws = 3)
     [ let smoke-appear patch-at-heading-and-distance direction  random 3
        if smoke-appear != nobody [ask smoke-appear [sprout-smoke 1 [set smoke-life random 200 set size 3 set heading direction set color [200 200 200 40]]] ]]
  if (cws = 4)
     [ let smoke-appear patch-at-heading-and-distance direction  random 5
        if smoke-appear != nobody [ask smoke-appear [sprout-smoke 1 [set smoke-life random 200 set size 3 set heading direction set color [200 200 200 40]]] ]]
end

to move-smoke
  if (cws = 2)  [ask smoke [fd .5]]
  if (cws = 3)  [ask smoke [fd 1]]
  if (cws = 4)  [ask smoke [fd 2]]
  ask smoke  [set smoke-life smoke-life + 1 ]
  ask smoke [if smoke-life > 180 [die]]
end

to ignite
  sprout-fires 1
    [ set color 45     set burnt burnt - 100
      ]
  if Protected-areas [ask self [if SAVED-IGNITION = 100 [explode set exploded 1] ]]
;  set pcolor black

end

;drop incendaries
to ignite-forest
;; light a fire where the user says to
  if (mouse-down?)
    [  ask patch mouse-xcor mouse-ycor
      [  sprout-fires 1
        [  set color 45
          ask patches in-cone 1 360
          [ sprout-fires 1
            [  set color 45
            ;;  set burnt burnt - 100   ]
                ]  ]]
        display      ]    ]
end

;re-ignite saved patches
to set-ignition
  ask patches with [SAVED-IGNITION = 1]
  [ sprout-fires 1 [set color 45 ]]
end

;Draw fire-break
to fire-break
  ;; create burnt cells where the user says to
  if (mouse-down?)
    [  ask patch mouse-xcor mouse-ycor
      [  sprout-ashes 1
        [  set color black
          ask patches in-cone 3 360
          [ sprout-ashes 1
            [  set color black
              set burnt burnt - 100   ]    ]  ]
        display      ]    ]
end

to fade-embers
    ask embers
    [ set  burnttime burnttime + 1
    if burnttime = 1 [set color [255 255 0 150]]
      if burnttime = 2 [set color  [255 255 0 150]]
      if burnttime = 3 [set color  [255 255 0 150]]
      if burnttime = 4 [set  color [255 255 0 150]]
      if burnttime = 5 [set color  25]
      if burnttime = 6 [set color  15]
      if burnttime = 7 [set color  27]
      if burnttime = 8 [set color  42]
      if burnttime = 9 [set  color 23]
      if burnttime = 10 [set color  26]
      if burnttime = 11 [set color  15]
      if burnttime = 12 [set color  24]
      if burnttime = 13 [set color  15]
      if burnttime > 60 / 3 and burnttime < 60 [set color  11]
      if burnttime > 60 [set pcolor 1 die]]
end


;***************************************************************************************
;******************************BURNABILITY LAYER ADJUSTMENTS****************************
;***************************************************************************************

to set-topowet
  set topowet wetness
  if ( wetness  > .7 and wetness < .8 and Fire_Danger = 10) [set topowet (1.4)]
  if ( wetness  > .8 and wetness < .9 and Fire_Danger = 7) [set topowet (1)]
  if ( wetness  > .8 and wetness < .9 and Fire_Danger > 7) [set topowet (1.2)]
  if ( wetness  > .9 and wetness < 1 and Fire_Danger = 7) [set topowet (1)]
  if ( wetness  > .9 and wetness < 1 and Fire_Danger > 7) [set topowet (1.1)]
  if ( wetness  > 1.05 and wetness < 1.1 and Fire_Danger > 8) [set topowet (1)]
  if ( wetness  > 1.1 and wetness < 1.15 and Fire_Danger > 7) [set topowet (1)]
  if ( wetness  > 1.15 and wetness < 1.2 and Fire_Danger > 8) [set topowet (.8)]
  if ( wetness  > 1.2 and wetness < 1.3 and Fire_Danger = 7) [set topowet (1.1)]
  if ( wetness  > 1.2 and wetness < 1.3 and Fire_Danger = 8) [set topowet (.8)]
  if ( wetness  > 1.2 and wetness < 1.3 and Fire_Danger > 8) [set topowet (.7)]
  if ( wetness  > 1.3 and Fire_Danger = 7) [set topowet (.8)]
  if ( wetness  > 1.3 and Fire_Danger = 8) [set topowet (.7)]
  if ( wetness  > 1.3 and Fire_Danger > 8) [set topowet (.6)]
end

to set-fuelload

   if veg = 1  [set fuelload (( -0.0054 * (tslb ^ 2)) + (0.0966 * tslb) + 0.87) ] ; tussock
   if veg = 2 [set fuelload ( (0.0014 * (tslb ^ 3)) + ( -0.0421 * (tslb ^ 2)) + ( 0.4243 * tslb) + 0.115) ] ;Hummock
   if veg = 3 [set fuelload ( (0.001115 * (tslb ^ 3)) + ( -0.03 * (tslb ^ 2)) + ( 0.28 * tslb) + 0.5) ] ; mixed
   if veg = 4  [set fuelload 0.1 ] ;main road
   if veg = 5  [set fuelload 0.4 ] ; 2nd road
   if veg = 6  [set fuelload 0.6 ] ; track
   if veg = 7  [set fuelload 0.1 ] ; fence - fire break
   if veg = 8  [set fuelload 0.3 ] ; fence
   if veg = 9  [set fuelload 0.7 ] ; riparian
   if veg = 10  [set fuelload 0.1 ] ; river
   if TSLB = 0 [set fuelload (.5)]
end



;***************************************************************************************
;***********************************SLOPE***********************************************
;***************************************************************************************
;; Need To Change With Difference Spatial Resolution

to calc-slope ;;NTC - with differeing cell size
  ;; calulate slope from a burning pixel to surrounding pixeles using elevation data
   let e1  [elevation]  of patch-at 0 1
   let s1 (e1 - [elevation]  of patch-here) / 80
   ask patch-at 0 1 [set slope ((0.4527 * s1) + 1)]

   let e2  [elevation]  of patch-at 1 0
   let s2 (e2 - [elevation]  of patch-here ) / 80
   ask patch-at 1 0 [set slope ((0.4527 * s2) + 1)]

   let e3  [elevation]  of patch-at 0 -1
   let s3 (e3 - [elevation]  of patch-here ) / 80
   ask patch-at 0 -1 [set slope ((0.4527 * s3) + 1)]

   let e4  [elevation]  of patch-at -1 0
   let s4 (e4 - [elevation]  of patch-here ) / 80
   ask patch-at -1 0 [set slope ((0.4527 * s4) + 1)]

   let e5  [elevation]  of patch-at 1 -1
   let s5 (e5 - [elevation]  of patch-here ) / 80
   ask patch-at 1 -1 [set slope ((0.4527 * s5) + 1)]

   let e6  [elevation]  of patch-at -1 -1
   let s6 (e6 - [elevation]  of patch-here ) / 80
   ask patch-at -1 -1 [set slope ((0.4527 * s6) + 1)]

   let e7  [elevation]  of patch-at 1 1
   let s7 (e7 - [elevation]  of patch-here ) / 80
   ask patch-at 1 -1 [set slope ((0.4527 * s7) + 1)]

   let e8  [elevation]  of patch-at -1 1
   let s8 (e8 - [elevation]  of patch-here ) / 80
   ask patch-at -1 -1 [set slope ((0.4527 * s8) + 1)]
end

;***************************************************************************************
;***********************************Time of Day***********************************************
;***************************************************************************************
;; Need To Change With Difference Spatial Resolution

to changeFire_Danger ;;NTC - with differeing cell size

if tod > 300 [set tod 0 set night night + 1]
if tod = 180 [set timeofday "night"
  ask patch 100 100 [ sprout-dots 1 [ set size 5000 set color [1 1 1 15]]]]
  if tod = 184 [ask dots [ set color [1 1 1 25]]]
  if tod = 186 [ask dots [ set color [1 1 1 30]]]
  if tod = 187 [ask dots [ set color [1 1 1 37]]]
  if tod = 188 [ask dots [ set color [1 1 1 42]]]
  if tod = 189 [ask dots [ set color [1 1 1 50]]]
  if tod = 191 [ask dots [ set color [1 1 1 65]]]
  if tod = 193 [ask dots [ set color [1 1 1 75]]]

if tod = 135 and wsv > 1 [set wsv int-ws - 1]
if tod = 14 and wsv < 4 and int-ws != 1 [set wsv int-ws]
  if tod = 1 [set timeofday "day" ask dots [ set color [1 1 1 55]]]
  if tod = 2 [ask dots [ set color [1 1 1 47]]]
  if tod = 4 [ask dots [ set color [1 1 1 40]]]
  if tod = 6 [ask dots [ set color [1 1 1 35]]]
  if tod = 8 [ask dots [ set color [1 1 1 25]]]
  if tod = 10 [ask dots [ set color [1 1 1 10]]]
  if tod = 12 [ask dots [ die]];

      if tod = 13 [set Fire_Danger Fire_Danger + 1 set timeod "Morning" ]
       if tod = 62 [set Fire_Danger Fire_Danger + 1 set timeod "Noon"]
        if tod = 112 [set Fire_Danger Fire_Danger + 1 set timeod "Afternoon"]
         if tod = 162  [set Fire_Danger Fire_Danger - 1 set timeod "Evening"]
          if tod = 212 [set Fire_Danger Fire_Danger - 1 set timeod "Evening"]
           if tod = 262 [set Fire_Danger Fire_Danger - 1 set timeod "early morning"]
            if tod = 287 [set Fire_Danger Fire_Danger - 1 set timeod "early morning"]
              if tod = 300 [set Fire_Danger Fire_Danger + 1 set timeod "Dawn"]

end

To set-time-of-day
  if set-time = "morning" [set tod 14 set timeod "morning" set Fire_Danger Fire_Danger - 1]
    if set-time = "noon" [set tod 63 set timeod "noon"]
      if set-time = "afternoon" [set tod 113 set timeod "afternoon" set Fire_Danger Fire_Danger + 1]
        if set-time = "evening" [set tod 163  set timeod "evening"]
end





;***************************************************************************************
;***********************************WIND INFLUENCE**************************************
;***************************************************************************************

to set-windspeed
  ;; setting wind speed influence on burn probability relative to wind direction
  if wind-speed = "none" [set int-ws 1 set wsv 1 set cws 1]
  if wind-speed = "light" [set int-ws 2 set wsv 2 set cws 2]
  if wind-speed = "medium" [set int-ws 3 set wsv 3 set cws 3]
  if wind-speed = "strong" [set int-ws 4 set wsv 4 set cws 4]
   if (wsv = 1)
      [set wd .5 set wd-1 .5 set wd-2 .5 set wd-3 .5 set wd-4 .5 set wd-5 .5 set wd-6 .5 set wd-7 .5 ]
   if (wsv = 2)
      [set wd .9 set wd-1 .9 set wd-2 .8 set wd-3 .7 set wd-4 .6 set wd-5 .7 set wd-6 .8 set wd-7 .9 ]
   if (wsv = 3 )
      [set wd 1.2 set wd-1 1 set wd-2 .8 set wd-3 .6 set wd-4 .5 set wd-5 .6 set wd-6 .8 set wd-7 1 ]
   if (wsv = 4)
      [set wd 1.5 set wd-1 .9 set wd-2 .4 set wd-3 .2 set wd-4 .1 set wd-5 .2 set wd-6 .4 set wd-7 .9 ]
end

to change-wind-speed
set windran random-float 1
let windchange  0
if (wsv = 1 and windchange = 0 and  cws = 1 and windran  < .05) [set windchange  1 set cws 2]
If (wsv = 1 and windchange = 0 and  cws = 2 and windran < .9) [set windchange  1 set cws 1]
if (wsv = 1 and windchange = 0 and  cws = 3 and windran  < .99) [set windchange  1 set cws 2]
If (wsv = 1 and windchange = 0 and  cws = 4 and windran < .99) [set windchange  1 set cws 2]


if (wsv = 2 and windchange = 0 and  cws = 1 and windran  < .6) [set windchange  1 set cws  2]
If (wsv = 2 and windchange = 0 and  cws = 2 and windran < .2) [set windchange  1 set cws  1]
If (wsv = 2 and windchange = 0 and  cws = 2 and windran >  .9) [set windchange  1 set cws  3]
If (wsv = 2 and windchange = 0 and  cws = 3 and windran < .8) [set windchange  1 set cws  2]
If (wsv = 2 and windchange = 0 and  cws = 3 and windran >  .995) [set windchange  1 set cws  4]
If (wsv = 2 and windchange = 0 and  cws = 4 and windran < .995) [set windchange  1 set cws  3]

if (wsv = 3 and windchange = 0 and  cws = 1 and windran  < .9) [set windchange  1 set cws  2]
If (wsv = 3 and windchange = 0 and  cws = 2 and windran < .1) [set windchange  1 set cws  1]
If (wsv = 3 and windchange = 0 and  cws = 2 and windran >  .6)  [set windchange  1 set cws  3]
If (wsv = 3 and windchange = 0 and  cws = 3 and windran < .2)   [set windchange  1 set cws  2]
If (wsv = 3 and windchange = 0 and  cws = 3 and windran > .96 ) [set windchange  1 set cws  4]
If (wsv = 3 and windchange = 0 and  cws = 4 and windran < .99 ) [set windchange  1 set cws  3]

if (wsv = 4 and windchange = 0 and  cws = 1 and windran  < .9) [set windchange  1 set cws  2]
If (wsv = 4 and windchange = 0 and  cws = 2 and windran < .1 ) [set windchange  1 set cws  1]
If (wsv = 4 and windchange = 0 and  cws = 2 and windran >  .4) [set windchange  1 set cws  3]
If (wsv = 4 and windchange = 0 and  cws = 3 and windran < .1) [set windchange  1 set cws  2]
If (wsv = 4 and windchange = 0 and  cws = 3 and windran >  .8) [set windchange  1 set cws  4]
If (wsv = 4 and windchange = 0 and  cws = 4 and windran < .6) [set windchange  1 set cws  3]

  set ember-rand (random-float 55)
   if (cws = 1)
      [set wd .8 set wd-1 .8 set wd-2 .8 set wd-3 .8 set wd-4 .8 set wd-5 .8 set wd-6 .8 set wd-7 .8 set ember-fly-dist 0]
   if (cws = 2)
      [set wd 1 set wd-1 .9 set wd-2 .8 set wd-3 .7 set wd-4 .7 set wd-5 .7 set wd-6 .8 set wd-7 .9 set ember-fly-dist 0]
   if (cws = 3 )
      [set wd 1.2 set wd-1 1 set wd-2 .7 set wd-3 .6 set wd-4 .5 set wd-5 .6 set wd-6 .7 set wd-7 1 set ember-fly-dist 0]
   if (cws = 4)
      [set wd 1.4 set wd-1 1 set wd-2 .4 set wd-3 .2 set wd-4 .1 set wd-5 .2 set wd-6 .4 set wd-7 1  set ember-fly-dist int(( (0.0031 * (ember-rand ^ 2)) + ( -0.0176 * (ember-rand)) +  0.2))]

end

to calc-windinfluence
 if (wind-direction = "S")
  [ ask patch-at 0 1 [set wind wd]
   ask patch-at 1 1 [set wind wd-1]
   ask patch-at 1 0 [set wind wd-2]
   ask patch-at 1 -1 [set wind wd-3]
   ask patch-at 0 -1 [set wind wd-4]
   ask patch-at -1 -1 [set wind wd-5]
   ask patch-at -1 0 [set wind wd-6]
   ask patch-at -1 1 [set wind wd-7]
   set direction 0 ]
 if (wind-direction = "SW")
  [ ask patch-at 0 1 [set wind wd-7]
   ask patch-at 1 1 [set wind wd]
   ask patch-at 1 0 [set wind wd-1]
   ask patch-at 1 -1 [set wind wd-2]
   ask patch-at 0 -1 [set wind wd-3]
   ask patch-at -1 -1 [set wind wd-4]
   ask patch-at -1 0 [set wind wd-5]
   ask patch-at -1 1 [set wind wd-6]
   set direction 45]
 if (wind-direction = "W")
  [ ask patch-at 0 1 [set wind wd-6]
   ask patch-at 1 1 [set wind wd-7]
   ask patch-at 1 0 [set wind wd]
   ask patch-at 1 -1 [set wind wd-1]
   ask patch-at 0 -1 [set wind wd-2]
   ask patch-at -1 -1 [set wind wd-3]
   ask patch-at -1 0 [set wind wd-4]
   ask patch-at -1 1 [set wind wd-5]
   set direction 90]
 if (wind-direction = "NW")
  [ ask patch-at 0 1 [set wind wd-5]
   ask patch-at 1 1 [set wind wd-6]
   ask patch-at 1 0 [set wind wd-7]
   ask patch-at 1 -1 [set wind wd]
   ask patch-at 0 -1 [set wind wd-1]
   ask patch-at -1 -1 [set wind wd-2]
   ask patch-at -1 0 [set wind wd-3]
   ask patch-at -1 1 [set wind wd-4]
   set direction 135]
 if (wind-direction = "N")
  [ ask patch-at 0 1 [set wind wd-4]
   ask patch-at 1 1 [set wind wd-5]
   ask patch-at 1 0 [set wind wd-6]
   ask patch-at 1 -1 [set wind wd-7]
   ask patch-at 0 -1 [set wind wd]
   ask patch-at -1 -1 [set wind wd-1]
   ask patch-at -1 0 [set wind wd-2]
   ask patch-at -1 1 [set wind wd-3]
   set direction 180]
 if (wind-direction = "NE")
  [ ask patch-at 0 1 [set wind wd-3]
   ask patch-at 1 1 [set wind wd-4]
   ask patch-at 1 0 [set wind wd-5]
   ask patch-at 1 -1 [set wind wd-6]
   ask patch-at 0 -1 [set wind wd-7]
   ask patch-at -1 -1 [set wind wd]
   ask patch-at -1 0 [set wind wd-1]
   ask patch-at -1 1 [set wind wd-2]
   set direction 135]
 if (wind-direction = "E")
  [ ask patch-at 0 1 [set wind wd-2]
   ask patch-at 1 1 [set wind wd-3]
   ask patch-at 1 0 [set wind wd-4]
   ask patch-at 1 -1 [set wind wd-5]
   ask patch-at 0 -1 [set wind wd-6]
   ask patch-at -1 -1 [set wind wd-7]
   ask patch-at -1 0 [set wind wd]
   ask patch-at -1 1 [set wind wd-1]
   set direction 270]
 if (wind-direction = "SE")
  [ ask patch-at 0 1 [set wind wd-1]
   ask patch-at 1 1 [set wind wd-2]
   ask patch-at 1 0 [set wind wd-3]
   ask patch-at 1 -1 [set wind wd-4]
   ask patch-at 0 -1 [set wind wd-5]
   ask patch-at -1 -1 [set wind wd-6]
   ask patch-at -1 0 [set wind wd-7]
   ask patch-at -1 1 [set wind wd]
   set direction 315]
end

;***************************************************************************************
;***********************************VIEW DATA LAYERS**************************************
;***************************************************************************************


To view-new
;to choose base map layer visualisation
 if View = "Place_NP" [import-pcolors-rgb "PNG/Jawoyn_WF_Place2.png"] ask patches [if (burnt < 100) [set pcolor 1] ]
 if View = "Place_IND" [import-pcolors-rgb "PNG/Jawoyn_AB_Place2.png"] ask patches [if (burnt < 100) [set pcolor 1] ]

 if View = "Grass" [import-pcolors-rgb "PNG/Jawoyn_LC.png"] ask patches [if (burnt < 100) [set pcolor 1] ]
 if View = "Roads" [import-pcolors-rgb "PNG/Jawoyn_Roads_Rivers.png"] ask patches [if (burnt < 100) [set pcolor 1] ]
 if View = "Hill Shade" [import-pcolors-rgb "PNG/Jawoyn_HS.png"] ask patches [if (burnt < 100) [set pcolor 1] ]
 if view = "YSLB"  [import-pcolors-rgb "PNG/Jawoyn_YSLB_19.png"] ask patches [if (burnt < 100) [set pcolor 1] ]
 if View = "DEM" [import-pcolors-rgb "PNG/Jawoyn_DEM.png"]ask patches [if (burnt < 100) [set pcolor 1] ]
 if view = "Landsat"  [import-pcolors-rgb "PNG/Jawoyn_SAT.png"]ask patches [if (burnt < 100) [set pcolor 1] ]
 if view = "Wetness"  [import-pcolors-rgb "PNG/Jawoyn_WET.png"]ask patches [if (burnt < 100) [set pcolor 1] ]
 if view = "Eco"  [import-pcolors-rgb "PNG/Jawoyn_Habitat.png"]ask patches [if (burnt < 100) [set pcolor 1] ]


end
to viewmonth
  if (monthburnt = "1") [ ask patches with [HotSpot_Burn < 31] [set dayofmonth 1 set monthname "Febuary"
    set dayofyear 30 set pcolor palette:scale-gradient palette:scheme-colors "Divergent" "Spectral" 7 HotSpot_Burn 300 90 ]]
  if (monthburnt = "2") [ ask patches with [HotSpot_Burn < 60] [set dayofmonth 1 set monthname "March"
    set dayofyear 59 set pcolor palette:scale-gradient palette:scheme-colors "Divergent" "Spectral" 7 HotSpot_Burn 300 90 ]]
  if (monthburnt = "3") [ ask patches with [HotSpot_Burn < 91] [set dayofmonth 1 set monthname "April"
    set dayofyear 90 set pcolor palette:scale-gradient palette:scheme-colors "Divergent" "Spectral" 7 HotSpot_Burn 300 90 ]]
  if (monthburnt = "4") [ ask patches with [HotSpot_Burn < 121] [set dayofmonth 1 set monthname "May"
    set dayofyear 121 set pcolor palette:scale-gradient palette:scheme-colors "Divergent" "Spectral" 7 HotSpot_Burn 300 90 ]]
  if (monthburnt = "5") [ ask patches with [HotSpot_Burn < 152] [set dayofmonth 1 set monthname "June"
    set dayofyear 152 set pcolor palette:scale-gradient palette:scheme-colors "Divergent" "Spectral" 7 HotSpot_Burn 300 90 ]]
  if (monthburnt = "6") [ ask patches with [HotSpot_Burn < 182] [set dayofmonth 1 set monthname "July"
    set dayofyear 182 set pcolor palette:scale-gradient palette:scheme-colors "Divergent" "Spectral" 7 HotSpot_Burn 300 90 ]]
  if (monthburnt = "7") [ ask patches with [HotSpot_Burn < 213] [set dayofmonth 1 set monthname "August"
    set dayofyear 213 set pcolor palette:scale-gradient palette:scheme-colors "Divergent" "Spectral" 7 HotSpot_Burn 300 90 ]]
  if (monthburnt = "8") [ ask patches with [HotSpot_Burn < 243] [set dayofmonth 1 set monthname "September"
    set dayofyear 243 set pcolor palette:scale-gradient palette:scheme-colors "Divergent" "Spectral" 7 HotSpot_Burn 300 90 ]]
  if (monthburnt = "9") [ ask patches with [HotSpot_Burn < 272] [set dayofmonth 1 set monthname "October"
    set dayofyear 272 set pcolor palette:scale-gradient palette:scheme-colors "Divergent" "Spectral" 7 HotSpot_Burn 300 90 ]]
  if (monthburnt = "10")[ ask patches with [HotSpot_Burn < 305] [set dayofmonth 1 set monthname "November"
    set dayofyear 305 set pcolor palette:scale-gradient palette:scheme-colors "Divergent" "Spectral" 7 HotSpot_Burn 300 90 ]]
  if (monthburnt = "11")[ ask patches with [HotSpot_Burn < 335] [set dayofmonth 1 set monthname "December"
    set dayofyear 335 set pcolor palette:scale-gradient palette:scheme-colors "Divergent" "Spectral" 7 HotSpot_Burn 300 90 ]]
  if (monthburnt = "12")[ ask patches with [HotSpot_Burn < 360] [set dayofmonth 1 set monthname "December"
    set dayofyear 360 set pcolor palette:scale-gradient palette:scheme-colors "Divergent" "Spectral" 7 HotSpot_Burn 300 90 ]]



end


to setup-patches
  import-pcolors-rgb "PNG/Jawoyn_HS.png"
  ask patches [set burnt burnt + 100]
  set dem-dataset gis:load-dataset "ASCII/Jawoyn_DEM-80.asc"
  set tslb-dataset gis:load-dataset "ASCII/Jawoyn_YSLB-19.asc"
  set veg-dataset gis:load-dataset "ASCII/Jawoyn_VEG4-80.asc"
  set wetness-dataset gis:load-dataset "ASCII/Jawoyn_WET-80.asc"
;  set burnt2018-dataset gis:load-dataset "ASCII/Jawoyn_Burnt_2018_EOJune.asc"
  set DOY-dataset gis:load-dataset "ASCII/Jawoyn_Burnt2018_DOY.asc"

  gis:apply-raster dem-dataset elevation
  gis:apply-raster tslb-dataset  tslb
  gis:apply-raster veg-dataset veg
  gis:apply-raster wetness-dataset wetness
  gis:set-world-envelope      (gis:envelope-of tslb-dataset)
  ask patches [  ifelse (tslb <= 0) or (tslb >= 0)  [ ] [ set tslb 1 ]  ]
  ask patches [  ifelse (wetness <= 0) or (wetness >= 0)  [ ] [ set wetness 1 ]  ]
  ask patches [  ifelse (veg <= 0) or (veg >= 0)  [ ] [ set veg 1 ]  ]
  ask patches [  ifelse (elevation <= 0) or (elevation >= 0)  [ ] [ set elevation 1 ]  ]

  gis:apply-raster  DOY-dataset HotSpot_Burn
 end


to save-ignition
  ask fires [ ask patch-here[set SAVED-IGNITION 1]]
end


;*********************************************************************************
;***********************************OUT_PUTS**************************************
;*********************************************************************************
to exp-ascii
   ;gis:set-world-envelope (list min-pxcor max-pxcor min-pycor max-pycor )
  ;let output-raster gis:create-raster world-width world-height gis:world-envelope
  let output-raster gis:patch-dataset totalout
  gis:store-dataset output-raster (word "/output/toutput" iteration ".asc")
  if iteration = 5 or iteration = 10 or iteration = 15 or iteration = 20 or iteration = 55 [ask patches [ set totalout 0] ]
end
to save-iter
  ask patches [if burnt < 100 [set burnt 1] ]
  ask patches [if burnt = 100 [set burnt 0]]
  if iteration = 1 [ask patches [ set totalout burnt]]
  if iteration > 1 [ask patches [ set out1 burnt set totalout (totalout + out1)]]
end


;;******************************* LABELS *********************************

to show-labels
  let mpx max-pxcor - 20
  let mpy min-pycor + 470
  ask patch (mpx - 30) (mpy + 150) [set plabel "kmsq"]
;  ask patch mpx (mpy + 150) [set plabel int burnt-area]
  ask patch (mpx - 20) (mpy + 125) [set plabel "day"] ; number of days
  ask patch (mpx - 70) (mpy + 125) [set plabel timeod] ; time of day
  ask patch (mpx - 5) (mpy + 125) [set plabel 1]
  ask patch (mpx - 50) (mpy + 100) [set plabel wind-speed]
  ask patch (mpx - 0) (mpy + 100) [set plabel "wind"]
  ask patch (mpx - 130) (mpy + 100) [set plabel wind-direction]
  let mp-x max-pxcor - 20
  let mp-y min-pycor + 510
  ask patch (mp-x - 910) (mp-y + 125) [set plabel "fire danger"]
  ask patch (mp-x - 880) (mp-y + 125) [set plabel int-fire-danger] ; fire danger
  ask patch (mp-x - 900) (mp-y + 150) [set plabel "fire weather"]
end
to update-labels
  let mpx max-pxcor - 20
  let mpy min-pycor + 470
  let mp-x max-pxcor - 20
  let mp-y min-pycor + 510
  ask patch (mpx - 5) (mpy + 150) [set plabel int burnt-area] ; km2
  ask patch (mpx - 70) (mpy + 125)  [set plabel timeod]
  ask patch  (mpx - 5) (mpy + 125) [set plabel int ((night) + 1)]
  ask patch (mp-x - 880) (mp-y + 150) [set plabel Fire_Danger] ; fire weather
end

to start-recorder
  carefully [ vid:start-recorder ] [ user-message error-message ]
end

to create-spinner
  create-spinners 1 [
    set shape "clock"
    setxy (max-pxcor - 30) (max-pycor - 30)
    set color white - 1.5
    set size 55
    set heading 0
  ]
    create-spinners 1 [
    set shape "clock2"
    setxy (max-pxcor - 30) (max-pycor - 30)
    set size 60
    set heading (tod * 2.4 + 150)
  ]
end

to save-recording
  if vid:recorder-status = "inactive" [
    user-message "The recorder is inactive. There is nothing to save."
    stop
  ]
  ; prompt user for movie location
  user-message (word
    "Choose a name for your movie file (the "
    ".mp4 extension will be automatically added).")
  let path user-new-file
  if not is-string? path [ stop ]  ; stop if user canceled
  ; export the movie
  carefully [
    vid:save-recording path
    user-message (word "Exported movie to " path ".")
  ] [
    user-message error-message
  ]
end

to explode
set SAVED-IGNITION 50
sprout-dots 30
   [ let randpat (random 2 + 4)
    let randcol (random 5 + 10)
      ask dots [pd repeat 10 [ set color randcol fd randpat  rt 10 ]]die]
;    ask dots [pd repeat 8 [ set color black fd 2 lt 5 ]]]
end
to protect-area
  ;; create burnt cells where the user says to
  if (mouse-down?)
    [  ask patch mouse-xcor mouse-ycor
        [  set SAVED-IGNITION 100 ask neighbors  [ set pcolor blue ]    ]
        display      ]
end
to burn-anim
  set dayofyear dayofyear + 1
   ask  patches with [HotSpot_Burn = dayofyear] [set pcolor palette:scale-gradient palette:scheme-colors "Divergent" "Spectral" 7 HotSpot_Burn 300 90 ]
  set dayofmonth dayofmonth + 1
  tick

  if dayofyear > 0  and dayofyear < 30 [set monthname "January"]   if monthname = "January" and dayofyear > 30 [set dayofmonth 1]
  if dayofyear > 30  and dayofyear < 59 [set monthname "Febuary"]   if monthname = "Febuary" and dayofyear > 59 [set dayofmonth 1]
  if dayofyear > 59  and dayofyear < 90 [set monthname "March" ]   if monthname = "March" and dayofyear > 90 [set dayofmonth 1]
  if dayofyear > 90  and dayofyear < 120 [set monthname "April"]    if monthname = "April" and dayofyear > 120 [set dayofmonth 1]
  if dayofyear > 120  and dayofyear < 151 [set monthname "May" ]   if monthname = "May" and dayofyear > 151 [set dayofmonth 1]
  if dayofyear > 151  and dayofyear < 181 [set monthname "June"]    if monthname = "June" and dayofyear > 181 [set dayofmonth 1]
  if dayofyear > 181  and dayofyear < 212 [set monthname "July"]    if monthname = "July" and dayofyear > 212 [set dayofmonth 1]
  if dayofyear > 212  and dayofyear < 243 [set monthname "August"]     if monthname = "August" and dayofyear > 243 [set dayofmonth 1]
  if dayofyear > 243  and dayofyear < 273 [set monthname "September"]     if monthname = "September" and dayofyear > 273 [set dayofmonth 1]
  if dayofyear > 273  and dayofyear < 304 [set monthname "October"]     if monthname = "October" and dayofyear > 304 [set dayofmonth 1]
  if dayofyear > 332  and dayofyear < 334 [set monthname "November"]     if monthname = "November" and dayofyear > 334 [set dayofmonth 1]
  if dayofyear > 334  [set monthname "dECEMBER"]     if dayofyear > 352 [stop]

  ask patch -420 -270 [set plabel monthname]
  ask patch -390 -270 [set plabel dayofmonth]
end
@#$#@#$#@
GRAPHICS-WINDOW
244
10
1281
708
-1
-1
1.0
1
19
1
1
1
0
0
0
1
-514
514
-344
344
1
1
1
ticks
20.0

BUTTON
61
51
227
86
Load model
setup\nset-fire-weather\nshow-labels\n
NIL
1
T
OBSERVER
NIL
0
NIL
NIL
1

BUTTON
54
136
144
178
Ignite
ignite-forest
T
1
T
OBSERVER
NIL
1
NIL
NIL
1

SLIDER
1283
66
1382
99
Fire_Danger
Fire_Danger
1
10
13.0
1
1
NIL
HORIZONTAL

CHOOSER
1290
202
1382
247
Wind-Direction
Wind-Direction
"N" "NE" "E" "SE" "S" "SW" "W" "NW"
7

CHOOSER
1287
113
1379
158
wind-speed
wind-speed
"none" "light" "medium" "strong"
3

BUTTON
148
184
229
218
Ignite Saved
clear\nset-ignition\nset-windspeed\ncreate-spinner\nset-fire-weather\nclear-all-plots\nshow-labels\n
NIL
1
T
OBSERVER
NIL
3
NIL
NIL
1

BUTTON
151
402
232
435
Lightning
ask one-of patches with [ elevation > 150 ] [ignite]
NIL
1
T
OBSERVER
NIL
!
NIL
NIL
1

BUTTON
67
442
148
475
Fire Break
fire-break
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
1394
62
1523
164
1-3 Very Low\n4-5 Low\n6-7 Medium\n8-9 High\n10  Severe
11
13.0
1

BUTTON
150
142
228
176
Save Ignition
save-ignition
NIL
1
T
OBSERVER
NIL
2
NIL
NIL
1

BUTTON
56
235
220
278
Reset
clear\nclear-drawing\nclear-turtles\nask patches [set saved-ignition 0]
NIL
1
T
OBSERVER
NIL
.
NIL
NIL
1

BUTTON
1289
440
1363
473
Vegetation
import-pcolors-rgb \"PNG/Jawoyn_LC2.png\"\nask patches [if (burnt < 100) [set pcolor black] ]\nset view \"Vegetation\"
NIL
1
T
OBSERVER
NIL
5
NIL
NIL
1

BUTTON
1368
440
1444
474
Fire History
import-pcolors-rgb \"PNG/Jawoyn_YSLB_19.png\"\nask patches [if (burnt < 100) [set pcolor black] ]\nset view \"YSLB\"
NIL
1
T
OBSERVER
NIL
6
NIL
NIL
1

BUTTON
1290
519
1362
553
Topography
import-pcolors-rgb \"PNG/Jawoyn_HS.png\"\nask patches [if (burnt < 100) [set pcolor black]]\n  set view \"Hill Shade\"
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
1292
560
1362
593
Elevation
import-pcolors-rgb \"PNG/Jawoyn_DEM.png\"\nask patches [if (burnt < 100) [set pcolor black]]\nset view \"DEM\"
NIL
1
T
OBSERVER
NIL
E
NIL
NIL
1

BUTTON
1289
482
1362
515
Wettness
import-pcolors-rgb \"PNG/Jawoyn_WET.png\"\n ask patches [if (burnt < 100) [set pcolor black]]\n  set view \"Wettness\"
NIL
1
T
OBSERVER
NIL
W
NIL
NIL
1

TEXTBOX
1296
370
1449
417
Landscape Maps
18
63.0
1

TEXTBOX
1284
36
1446
54
Fire weather\n
18
13.0
1

TEXTBOX
123
100
165
126
Play
20
104.0
1

TEXTBOX
85
36
235
68
press this button first
12
14.0
1

TEXTBOX
80
315
205
359
Additional Settings
15
0.0
1

BUTTON
1288
403
1359
436
Places
import-pcolors-rgb \"PNG/Jawoyn_AB_Place2.png\"\nask patches [if (burnt < 100) [set pcolor black]]\n  set view \"Place_IND\"
NIL
1
T
OBSERVER
NIL
H
NIL
NIL
1

BUTTON
1369
478
1445
513
Roads/Rivers
import-pcolors-rgb \"PNG/Jawoyn_Roads_Rivers.png\"\nask patches [if (burnt < 100) [set pcolor black]]\nset view \"Roads\"\n
NIL
1
T
OBSERVER
NIL
9
NIL
NIL
1

BUTTON
154
442
228
476
Fuel Load
ask patches [ set pcolor palette:scale-gradient palette:scheme-colors \"Divergent\" \"Spectral\" 7 fuelload 0 1.6\n ]\n \nask patches [if (burnt < 100) [set pcolor black]]\n  set view \"Burnability\"
NIL
1
T
OBSERVER
NIL
B
NIL
NIL
1

BUTTON
1290
162
1381
195
Change Speed
set-windspeed
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
1290
254
1383
299
set-time
set-time
"morning" "noon" "afternoon" "evening"
2

BUTTON
55
183
145
223
GO
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
118
628
268
646
Options\n
14
0.0
1

BUTTON
1290
318
1393
352
SET Fire Weather
set-fire-weather\nask spinners [die]\ncreate-spinner\n  let mpx max-pxcor - 20\n  let mpy min-pycor + 510\n  ask patch (mpx - 880) (mpy + 150) [set plabel Fire_Danger]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
91
696
201
729
time-of-day
time-of-day
0
1
-1000

SWITCH
91
654
207
687
Stop-if-no-fire
Stop-if-no-fire
0
1
-1000

CHOOSER
1282
637
1374
682
monthburnt
monthburnt
"3" "4" "5" "6" "7" "8" "9" "10" "11" "12"
1

BUTTON
1380
644
1470
679
viewmonth
view-new\nset dayofyear 0\nviewmonth\nset dayofyear dayofyear
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
83
564
189
598
Save Picture
export-view (word \"Output/\"  \"FireDanger\" fire_danger wind-speed Wind-Direction \".png\")
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1372
518
1445
551
Satelite
import-pcolors-rgb \"PNG/Jawoyn_Sat.png\"\nask patches [if (burnt < 100) [set pcolor black]]\nset view \"Landsat\"
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
81
526
138
559
Vid Start
Start-recorder
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
146
524
202
557
Vid Save
save-recording
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1366
403
1447
437
Places NP
import-pcolors-rgb \"PNG/Jawoyn_WF_Place2.png\"\nask patches [if (burnt < 100) [set pcolor black]]\n set view \"Place_NP\"\n ask patch -66 16   [  set SAVED-IGNITION 100 ask neighbors  [ set pcolor blue ]  ]\n ask patch -104 112   [  set SAVED-IGNITION 100 ask neighbors  [ set pcolor blue ]  ]\n  ask patch -171 184   [  set SAVED-IGNITION 100 ask neighbors  [ set pcolor blue ]  ]\n   ask patch -91 -46   [  set SAVED-IGNITION 100 ask neighbors  [ set pcolor blue ]  ]\n  ask patch -109 -99   [  set SAVED-IGNITION 100 ask neighbors  [ set pcolor blue ]  ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
120
502
176
521
Record
14
14.0
1

BUTTON
69
402
146
436
NIL
protect-area
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
76
360
212
393
Protected-areas
Protected-areas
0
1
-1000

BUTTON
1283
689
1386
724
Animimate Burns
burn-anim
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
101
118
188
137
-----------
20
105.0
1

TEXTBOX
99
296
187
318
---------------
16
0.0
1

TEXTBOX
97
604
264
626
---------------
16
0.0
1

TEXTBOX
102
474
269
496
---------------
16
0.0
1

MONITOR
1393
686
1480
731
Date
list (monthname) (dayofmonth)
17
1
11

TEXTBOX
1290
607
1457
629
Previous Year Burn
16
0.0
1

BUTTON
1371
560
1450
593
Ecosystem
import-pcolors-rgb \"PNG/Jawoyn_Habitat.png\"\n set view \"Place_Eco\"
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
1390
167
1540
195
Press if changing wind speed\nwhilst the model is running
11
0.0
1

TEXTBOX
1403
324
1553
352
Save fire weather\nbefore pressing GO
11
0.0
1

BUTTON
1452
440
1519
473
Freq 19-15
import-pcolors-rgb \"PNG/Jawoyn_FF_19-15.png\"\nask patches [if (burnt < 100) [set pcolor black] ]\nset view \"YSLB\"
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1454
481
1521
514
Freq 05-09
import-pcolors-rgb \"PNG/Jawoyn_FF_05-09.png\"\nask patches [if (burnt < 100) [set pcolor black] ]\nset view \"YSLB\"
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This model is a work in progress for a north Australian landscape fire simulation game. The primary idea is to show how a range of variables effect fire spread when conducting aerial incendiary management burns early in the dry season and how these fuel reduction fires effect the spread of late season wild fires.


## HOW IT WORKS

The model currently uses the following variable to determine if a pixel will ignite:

- a grass vegetation map derved from Landsat Satellite imagery and a time since burnt layer (from NAFI) to produce a fuel load variable.  The  vegetation layer shows grass, low cover and mangrove types.

- an elevation layer (SRTM-DEM) is used to determine slope in relation to fire spread direction.

- a topographic wetness layer, derived from the DEM, is used to represent differntial landscape curing.

- Fire danger as an value from 1 (wet season) to 10 (late dry season). This combines the influence of curing and temperature on fire spread.

- Wind speed from none (no wind influence) to strong. Wind speed increses the directionality and likelyhood of a pixel ignighting.

- wind direction (the direction a fire will spread)


## HOW TO USE IT

Click the drop incendaries button and use the cursor to ignite some initial pixels. Change curing, wind direction and wind speed to set your fire senario. Use the variable-wind button to allow the model to  randomly change the wind speed as the model runs. Use the view drop list to display a one of a range of landscape layers.


## THINGS TO NOTICE

Fires should not run down slope as well as up slope.
Fire do not burn will on recently burnt hummock grasslands.

## THINGS TO TRY

Try running the model to set fire breaks early in the in the dry season (fire danger 6-7) then run the model with some single ignition points late in the dry (curing 9-10). Are you able to prevent fires spreading through your early season burns.

Try runing the model with some of the different landscape layers displayed.

Try running it projected over a sandpit sculpted with refernece to the elevation layer.

## EXTENDING THE MODEL

- Variable fire spread speed
- Burn severity
- An estimate of chopper time/cost
- An estimate of burn cost to burn area and fire severity as a measure of management     burn effectiveness.


## RELATED MODELS

Based on the fire break model.

## CREDITS AND REFERENCES

This model was produced in May 2017, More information about the model can be found at: https://rohanfisher.wordpress.com/incendiary-a-fire-spread-modelling-tool/

Copyright 2017 Rohan Fisher.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

clock
true
0
Circle -7500403 true true 30 30 240
Polygon -16777216 true false 150 31 128 75 143 75 143 150 158 150 158 75 173 75
Circle -16777216 true false 135 135 30

clock2
true
0
Circle -16777216 true false 120 120 60
Polygon -16777216 true false 150 31 128 75 143 75 143 150 158 150 158 75 173 75
Circle -16777216 true false 135 135 30

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Export multiple  burns as pictures" repetitions="1" runMetricsEveryStep="true">
    <setup>clear
set-ignition
set-fire-weather
set iteration iteration + 1</setup>
    <go>go</go>
    <final>save-iter
export-view (word "Output/"int-fire-danger"-"Wind-Speed".png")</final>
    <exitCondition>count turtles &lt; 1 or 
ticks &gt; 1000</exitCondition>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="Wind-Speed">
      <value value="&quot;none&quot;"/>
      <value value="&quot;light&quot;"/>
      <value value="&quot;medium&quot;"/>
      <value value="&quot;strong&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Wind-Direction">
      <value value="&quot;SE&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-of-day">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="set-time">
      <value value="&quot;afternoon&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Fire_Danger">
      <value value="2"/>
      <value value="5"/>
      <value value="7"/>
      <value value="9"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Export multiple  burns as pictures - multi variable" repetitions="1" runMetricsEveryStep="true">
    <setup>clear
set-ignition
set-windspeed
set-fire-weather
clear-all-plots
show-labels
set iteration iteration + 1</setup>
    <go>go</go>
    <final>save-iter
export-view (word "Output/" iteration ".png")</final>
    <exitCondition>count turtles &lt; 1</exitCondition>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="Wind-Speed">
      <value value="&quot;none&quot;"/>
      <value value="&quot;medium&quot;"/>
      <value value="&quot;strong&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Wind-Direction">
      <value value="&quot;E&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-of-day">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Fire_Danger">
      <value value="2"/>
      <value value="4"/>
      <value value="7"/>
      <value value="9"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Export multiple  burns as pictures - multi variable sp" repetitions="1" runMetricsEveryStep="true">
    <setup>clear
set-ignition
set-windspeed
set-fire-weather
clear-all-plots
show-labels
set iteration iteration + 1</setup>
    <go>go</go>
    <final>save-iter
export-view (word "Output/" iteration ".png")</final>
    <exitCondition>count turtles &lt; 1</exitCondition>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="Wind-Speed">
      <value value="&quot;medium&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Wind-Direction">
      <value value="&quot;E&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-of-day">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variable-wind">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Fire_Danger">
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
