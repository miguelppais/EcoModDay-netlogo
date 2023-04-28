extensions [csv matrix]

globals[
  night
  wind

  ;regression coefficients:
  intercept
  c_age
  c_height
  c_sex
  c_wind
  c_night
  c_interference
  R^2
  r ; logistic growth rate
]

breed[indicators indicator]

breed[predators predator]

breed[preys prey]

patches-own[
  nutrients
]

predators-own[
  energy
  height
  sex
  age
  success-rate
]

preys-own[
  energy

]

to startup
  ifelse user-yes-or-no? "Hello! Welcome to the Ecological Modelling Day ABM! Did you put the input.csv file on the same folder as the model?" [
    user-message "Ok, the model will now extract the data from the csv and calculate a linear model of the variable effects on predation success. Everytime you press setup the model will recalculate the coefficients. Have fun!"
    setup]
  [user-message "Ok, so close the model and go do that first!" stop]
end


to setup
  ca
  stop-inspecting-dead-agents
  set-default-shape predators "person"
  set-default-shape preys "circle"
  import-data-and-calculate-effects
  generate-landscape
  populate-landscape
  reset-ticks
end


to go
  if not any? predators [user-message "All predators are dead" stop]
  if not any? preys [user-message "There is no prey left..." stop]
  update-wind
  if ticks mod 48 = 0 [update-light]
  ask predators [
    check-starvation
    ifelse any? preys-here [hunt] [move]
    reproduce-predator
  ]

  ask preys [
    check-starvation
    move
    forage
    reproduce-prey
  ]

  ask patches [regrow]



  tick
end


;; OBSERVER PROCEDURES

to import-data-and-calculate-effects
  let data remove-item 0 (csv:from-file "input.csv" ";") ;import and clip header
  set data matrix:from-column-list data ; transpose data so that matrix rows are now the variables
  set data matrix:to-row-list data ; convert back to list
  repeat 5 [set data remove-item 6 data] ; remove the attempts columns (we don't need them)
  set data matrix:from-column-list data
  matrix:swap-columns data 6 0
  ;show data  ; debug
  let regression matrix:regress data ; multiple regression with 7 explanatory vars
  ;show regression ; debug
  set intercept item 0 (item 0 regression)
  set c_age item 6 (item 0 regression)
  set c_height item 1 (item 0 regression)
  set c_sex item 2 (item 0 regression)
  set c_wind item 3 (item 0 regression)
  set c_night item 4 (item 0 regression)
  set c_interference item 5 (item 0 regression)
  set R^2 item 0 (item 1 regression)
end


to generate-landscape
  create-indicators 1 [  ; create the wind symbol
    setxy 28 28
    set size 2
    set shape "arrow"
    set color black
    set label word "wind " wind
  ]
  create-indicators 1 [ ; create the sun/moon symbol
    setxy 2 28
    set size 3
    set shape "sun"
    set color yellow
  ]

  set night 0
  set wind 0
  ask patches [
    set nutrients 10
    update-color
  ]
end

to populate-landscape
  create-predators initial-number-of-predators [
    set energy 100
    set sex one-of [1 2]
    move-to one-of patches
    set height (random-between 150 200)
    set size height / 200
    set success-rate fixed-success-rate ;starting conditions
    ifelse sex = 2 [set color blue] [set color pink]
  ]

  create-preys initial-number-of-prey [
    set color white
    set size 0.3
    set energy 100
    move-to one-of patches


  ]

end




;; TURTLE PROCEDURES

to check-starvation
  if energy < 0 [die]
end

to move
  move-to one-of neighbors
  set energy energy - movement-cost
end

to reproduce-prey
if energy > 200 [
    set energy energy - 100
    hatch 1 [
      set energy 100
    ]
  ]
end

to reproduce-predator
if energy > 200 [
    set energy energy - 100
    hatch 1 [
      set energy 100
      set sex one-of [1 2]
      ifelse sex = 2 [set color blue] [set color pink]
      set height (random-between 150 200)
      set size height / 200
    ]
  ]
end

to hunt
  if any? preys-here [
    let interfered 0
    if any? predators-here [set interfered 1]
    let wind-convert (wind / 8)  ; wind will be 1 only at strength 8, otherwise we scale it down
    ifelse fixed-success-rate? [set success-rate fixed-success-rate] [set success-rate (intercept + (c_age * age)  + (c_height * height) + (c_sex * sex) + (c_night * night) + (c_interference * interfered) + (c_wind * wind-convert))]
    let food one-of preys-here
    if bernoulli success-rate [
      ask food [die]
      set energy energy + energy-from-prey
    ]
  ]
end

to forage
  if ( nutrients >= energy-from-nutrients ) [
    set energy energy + energy-from-nutrients
    set nutrients nutrients - energy-from-nutrients
    ask patch-here [update-color]
  ]
end

to update-wind
  set wind wind + random-between -1 1
  if wind > 8 [set wind 8]
  if wind < 0 [set wind 0]
  ask indicator 0 [
    set heading heading + random-between -2 2
    set label word "wind " wind
  ]
end

to update-light
  ifelse night = 1 [
    ask indicator 1 [set shape "sun" set color yellow]
    set night 0
  ] [
    ask indicator 1 [set shape "moon" set color gray]
    set night 1
  ]

end

;; PATCH PROCEDURES

to regrow
  set nutrients nutrients + nutrients-growth-rate
  if nutrients > 10.0 [set nutrients 10.0]
  update-color
end

to update-color
  set pcolor scale-color green (10 - nutrients) -10 20
end

to sexual-reproduction


end

;; REPORTERS

to-report random-between [low high]
  report random (high - low + 1) + low
  end

to-report bernoulli [p]
  report random-float 1 < p
end
@#$#@#$#@
GRAPHICS-WINDOW
200
60
828
689
-1
-1
20.0
1
10
1
1
1
0
1
1
1
0
30
0
30
1
1
1
ticks
30.0

BUTTON
25
60
105
110
NIL
setup
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
110
60
190
110
NIL
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

BUTTON
110
115
190
160
step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
835
60
1325
245
Populations
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" "if ticks > 10000 [set-plot-x-range ticks - 10000 ticks + 10]"
PENS
"Predator population (x10)" 1.0 0 -2674135 true "" "plot count predators * 10"
"Prey population" 1.0 0 -16777216 true "" "plot count preys"

PLOT
835
250
1175
370
Wind strength
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" "if ticks > 150 [set-plot-x-range ticks - 140 ticks + 10]"
PENS
"default" 1.0 0 -13791810 true "" "plot wind"

PLOT
835
370
1175
490
Time of day
NIL
NIL
0.0
10.0
0.0
3.0
true
false
"" "if ticks > 150 [set-plot-x-range ticks - 140 ticks + 10]"
PENS
"default" 1.0 0 -16777216 true "" "ifelse (night = 0) [plot 2] [plot 1]"

TEXTBOX
1180
405
1215
425
day
15
85.0
1

TEXTBOX
1180
435
1215
455
night
15
0.0
1

MONITOR
345
730
402
775
NIL
c_age
3
1
11

MONITOR
410
730
467
775
NIL
c_height
3
1
11

MONITOR
475
730
532
775
NIL
c_sex
3
1
11

MONITOR
265
730
330
775
NIL
intercept
3
1
11

MONITOR
545
730
602
775
NIL
c_wind
3
1
11

MONITOR
605
730
662
775
NIL
c_night
3
1
11

MONITOR
665
730
757
775
NIL
c_interference
3
1
11

TEXTBOX
370
705
505
725
internal attributes
15
15.0
1

TEXTBOX
590
705
740
723
external factors
15
15.0
1

MONITOR
765
715
830
776
R2
R^2
2
1
15

TEXTBOX
75
705
250
723
LINEAR MODEL COEFFICIENTS
13
95.0
1

TEXTBOX
115
750
260
775
Predation success rate = 
13
0.0
1

SLIDER
7
175
192
208
initial-number-of-predators
initial-number-of-predators
10
500
50.0
10
1
NIL
HORIZONTAL

SLIDER
7
210
192
243
initial-number-of-prey
initial-number-of-prey
10
500
200.0
10
1
NIL
HORIZONTAL

SLIDER
5
280
190
313
movement-cost
movement-cost
0
2
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
5
400
190
433
nutrients-growth-rate
nutrients-growth-rate
0
2
1.5
0.1
1
NIL
HORIZONTAL

SLIDER
5
320
190
353
energy-from-prey
energy-from-prey
0
5
4.0
0.1
1
NIL
HORIZONTAL

SLIDER
5
360
190
393
energy-from-nutrients
energy-from-nutrients
0
5
2.6
0.1
1
NIL
HORIZONTAL

PLOT
835
490
1175
610
Average predation success rate
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" "if ticks > 150 [set-plot-x-range ticks - 140 ticks + 10]"
PENS
"default" 1.0 0 -955883 true "" "plot mean [success-rate] of predators"

SWITCH
5
555
190
588
fixed-success-rate?
fixed-success-rate?
1
1
-1000

SLIDER
5
590
190
623
fixed-success-rate
fixed-success-rate
0.1
1
0.5
0.1
1
NIL
HORIZONTAL

TEXTBOX
10
260
110
278
BIOENERGETICS
11
0.0
1

TEXTBOX
15
640
185
681
If not fixed, success rate is calculated from the linear model
11
0.0
1

BUTTON
25
115
105
160
Reset defaults
set initial-number-of-predators 50\nset initial-number-of-prey 200\nset nutrients-growth-rate 1.5\nset movement-cost 0.5\nset energy-from-prey 4\nset energy-from-nutrients 2.6\nset fixed-success-rate? false\nset fixed-success-rate 0.5
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
25
10
960
50
Agent-based predator-prey model  -  Ecological Modelling Day, FCUL
30
94.0
1

TEXTBOX
840
620
1105
685
Author:\nMiguel Pessanha Pais, MARE (mppais@fc.ul.pt)
16
0.0
1

@#$#@#$#@
## WHAT IS IT?

This is a simple predator-prey model created to support an activity for the Ecological Modelling Day at the Faculty of Sciences, Univeristy of Lisbon.

It uses data gathered from people performing a challenge (throwing a ball at a hole) to determine the predation success rate. Several external factors are acting upon the person, namely night, wind and interference from another person. The effects of these factors are combined using a multiple linear regression.

## HOW IT WORKS



## HOW TO USE IT



## THINGS TO NOTICE

Notice how the average predation success changes with external factors, also notice how the populations of prey, predators and "grass" change and oscillate with time.

Notice what's happenning at different trime scales. The individual movement and preying decisions, the day and night cycle, the population cycles. How are they affected by variables?

## THINGS TO TRY

Change a few variables and try to see how it affects population changes. Can you keep the system going or does it collapse? Why did it collapse? Turn off "update changes" to run the model at maximum speed.

## EXTENDING THE MODEL

The model can be extended to include evolution of the most successful attributes.

## NETLOGO FEATURES

This model uses the csv extension to import data from a csv file and the matrix extension to convert the csv data to a matrix format and perform an ordinary least squares regression.

## RELATED MODELS

This model uses concepts from predator-prey models found in the model library, particularly the model from chapter 4 of the ABM book.

## CREDITS AND REFERENCES

(c) Miguel Pessanha Pais 2019

Model created under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International Public License. For more info go to https://creativecommons.org/licenses/by-nc-sa/4.0/
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

moon
false
0
Polygon -7500403 true true 175 7 83 36 25 108 27 186 79 250 134 271 205 274 281 239 207 233 152 216 113 185 104 132 110 77 132 51

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
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

sun
false
0
Circle -7500403 true true 75 75 150
Polygon -7500403 true true 300 150 240 120 240 180
Polygon -7500403 true true 150 0 120 60 180 60
Polygon -7500403 true true 150 300 120 240 180 240
Polygon -7500403 true true 0 150 60 120 60 180
Polygon -7500403 true true 60 195 105 240 45 255
Polygon -7500403 true true 60 105 105 60 45 45
Polygon -7500403 true true 195 60 240 105 255 45
Polygon -7500403 true true 240 195 195 240 255 255

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
1
@#$#@#$#@
