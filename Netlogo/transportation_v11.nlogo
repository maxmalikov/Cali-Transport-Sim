extensions [gis csv nw profiler vid bitmap profiler]
breed [people person] ;simulate people

;1:100 1 agent 100 people rounded

;nw:save-gexf
;nw:save-gml  "example.graphml"

;---------------Gloabl Variables------------------
globals[
  my-gis-dataset         ;gis dataset
  my-csv-dataset         ;list with parameters imported from csv
  cost-buy-mot
  cost-buy-car
  cost-buy-pub
  buy-increase-m
  buy-increase-c
  costf-op-mot
  costf-op-car
  costf-op-pub
  comfort-m
  comfort-c
  comfort-p
  gas-price
  eff-mot
  eff-car
  emi-mot
  emi-car
  emi-pub
  acc-rate-mot     ; accident rate for motorcycles
  acc-rate-car     ; accident rate for cars
  acc-rate-pub     ; accident rate for public transit
  acc-mot-count    ; count of accidents per decision period for motorcycles
  acc-car-count    ; count of accidents per decision period for cars
  acc-pub-count    ; count of accidents per decision period for public transit
  insecur-m        ; insecurity rate for motorcycles
  insecur-c        ; insecurity rate for cars
  insecur-p        ; insecurity rate for public transport
  inc-mot-count    ; count of incidents per decision period for motorcycles
  inc-car-count    ; count of incidents per decision period for cars
  inc-pub-count    ; count of incidents per decision period for public transit

  pollution-tot    ; score for the pollution of the complete system
  scaling-factor   ; determines how much to divide population for - used in testing.Defined in Initialization Function
  max-costv        ; max variable operating cost in the system, used to calculate op-cost scores
  min-costv        ; min variable operating cost in the system, used to calculate op-cost scores
  capacity-public  ; passengers capcity in the public system
  reg-speed-pub    ; regular speed of public system with current capacity
  default-wait-time; current waiting time of the system, minutes calculated with the numer of buses coming per hour  (60 / rate of buses)
  p-buy p-ope p-saf p-sec p-com p-tim p-pol ;Weights for low-income people
  p-buy2 p-ope2 p-saf2 p-sec2 p-com2 p-tim2 p-pol2 ;Weights for middle-income people
  p-buy3 p-ope3 p-saf3 p-sec3 p-com3 p-tim3 p-pol3 ;Weights for high-income people
  alpha beta ;Uncertainty Parameters
  commitment

]

;---------------Patch Attributes---------------
patches-own[
  CID      ;; Community ID
  PID      ;; Polygon ID number

  centroid? ;;if it is the centroid of a polygon
  community-social-type ;
  male-15-24
  female-15-24
  male-25-59
  female-25-59
  male-60
  female-60
  plow
  pmed
  phigh
  occupied?
]

;---------------Agent Attributes---------------
people-own[
  ;Genral attribute
  node-id
  hID             ;;person ID
  h-social-type   ;;person social type
  hPoly           ;;person polygonID
  gender          ;;1 male 2 female
  age             ;; 15 to 60 years
  destination-community ;1 TO 22
  t-type          ;;1 car 2 moto 3 bus
  speed           ;; actual speed depending on the current mode
  speed-m         ; speed normally distributed for motorcycle
  speed-c         ; speed normally distributed for car
  speed-p         ; speed normally distributed for public
  speed-mot       ; speed affected by congestion for motorcycle
  speed-car       ; speed affected by congestion for car
  speed-pub       ; speed affected by congestion for public
  density          ; excess of equivalent cars in 8 neighbor patches around (calculated over the base case)
  dist-trip       ; distance ; distance traveled at each tick
  kms             ; accumulated distance traveled during the decision period
  home-location   ; patch in the assigned commune of origin
  workplace       ; patch in the assigned commune of destination
  dist-home-work  ; Distance home - workplace
  safety          ; 1= road accident, 0= no road accident
  security        ; 1= personal security incident, 0= no personal security incident
  safety-mot      ; safety score used for satisfaction function mot
  safety-car      ; safety score used for satisfaction function car
  safety-pub      ; safety score used for satisfaction function pub
  inc-nw-m-count  ; count of security incidents in network per decision period for motorcycles
  inc-nw-c-count  ; count of security incidents in network per decision period for car
  inc-nw-p-count  ; count of security incidents in network per decision period for public transit
  security-mot    ; security score used for satisfaction function mot
  security-car    ; security score used for satisfaction function car
  security-pub    ; security score used for satisfaction function pub
  costv-mot       ; variable cost if the person is using a motorcycle
  costv-car       ; variable cost if the person is using a car
  costv-op-mot    ; score for variable operating cost of motorcycle (variables: gasoline)
  costv-op-car    ; score for variable operating cost of car (variables: gasoline)
  cost-op-mot     ; score for total operating cost of mot (the combination of variable and fixed)
  cost-op-car     ; score for total operating cost of car (the combination of variable and fixed)
  cost-op-pub     ; score for total operating cost of pub (fixed)
  pollution       ; pollution generated by the current transport mode
  comfort-mot     ; comfort score used for satisfaction function mot (percepction towards mot)
  comfort-car     ; comfort score used for satisfaction function car (percepction towards car)
  comfort-pub     ; comfort score used for satisfaction function pub (percepction towards pub)
  comfort         ; level of comfort perception towards current mode
  time-m          ; time of travel if the person is using a motorcycle
  time-c          ; time of travel if the person is using a car
  time-p          ; time of travel if the person is using public transit
  time            ; time of travel with the current mode
  time-mot        ; time score used for satisfaction function mot
  time-car        ; time score used for satisfaction function car
  time-pub        ; time score used for satisfaction function pub
  wait-time-p     ; waiting time for public transit users
  uncertainty-threshold   ; level of uncertaintiy tolerated
  satisfaction-threshold  ; level of satisfaction people wish to experiment with the trips
  satisfaction-mot; travel satisfaction if the person is using a motorcycle
  satisfaction-car; travel satisfaction if the person is using a car
  satisfaction-pub; travel satisfaction if the person is using public transportation
  w-buy w-ope w-saf w-sec w-com w-tim w-pol ; weights (level of importance) for attributes of transport modes buy= purchase, ope= operation, saf= road safety, sec= personal security, com= comfort, tim= time of travel, pol= pollution
  satisfaction    ; calculated in every period of decision according to needs satisfied with transport modes
  uncertainty     ; calculated in every period of decision according to the experience with transport modes
  neighborsmymode ; number of neighbors with the same agent's transport mode
  experience-mot  ; # of times that motorcycle has been selected
  experience-car  ; # of times that car mode has been selected
  experience-pub  ; # of times that public transit has been selected
  experience      ; experience with the current transport mode
  type-choice     ; according to the CONSUMAT model "repetition", "imitation", "deliberation", "inquiring"
  utility         ; intermediate calculation of satisfaction use by inquirers
  car-owner     ; 1-yes, 0-no
  moto-owner    ; 1-yes, 0-no
  arrived?      ; true- made it to destination, false- commuting
]

links-own [
  relationship-type
  original
]


;;************************;;
;;****1 Initialization****;;
;;************************;;
;1.1 Set up
to setup


  ;profiler:start
  reset-timer
  clear-all
  clear-drawing
  ;set time 0
  reset-ticks
  resize-world 0 149 0 149 set-patch-size 5
  ;Load Vector Boundary my-csv-dataset
  ;set my-gis-dataset gis:load-dataset "Data/test.shp"
  ;set my-gis-dataset gis:load-dataset "data/raw_data/shp/cali_community_wgs84.shp"
  set my-gis-dataset gis:load-dataset "cali_community_demo_wgs84.shp"
  set my-csv-dataset csv:from-file "inputs.csv" ; imports values for parameters
  import-drawing "cali_map.png" ; set background image

  ; Calculation variables of waiting time for Public transit (per decision period)
  set capacity-public   first (item 26 my-csv-dataset) ; number of passengers that the system can move
  set reg-speed-pub     first (item 27 my-csv-dataset) ; average regular speed of public system with the current capacity
  set default-wait-time first (item 28 my-csv-dataset) ; defuault waiting time in the public system at normal capacity

  draw ;draw the shp of cali

  ;1 setup population
  initilize-population

  set-h-social-type
  distribute-people

  set-destination ;

  set-transportation-type

  set-uncertainty-threshold

  set-satisfaction-threshold

  set-weights

  set-speed



  ;create-small-world-network
  ;create-small-world-network2
  ;create-small-world-network3
  ;create-preferential-network
  ;create-social-network
  ;create-social-network-fast
  create-social-network-fast2
  ;nw:save-matrix "matrix-0-sn2.csv"
  ;csv:to-file "results-0-sn2.csv" [ (list who h-social-type link-neighbors [h-social-type] of link-neighbors) ] of turtles
  show "Initialization Done!"
  show timer
  ;nw:save-graphml "sim_network.graphml"
  ;profiler:stop
  ;print profiler:report
end

;1.2 Draw the Doundary and Assign each Polygon ID
to draw
  show "loading map"
  gis:set-world-envelope gis:envelope-of (my-gis-dataset)
  show gis:property-names my-gis-dataset
  gis:apply-coverage my-gis-dataset "COMMUNITY" CID
  gis:apply-coverage my-gis-dataset "CTYPE" community-social-type

  ;"C_M_5_24" "C_F_15_24" "C_M_25_59" "C_F_25_59" "C_M_60" "C_F_60" "P_LOW" "P_MED" "P_HIGH"
  gis:apply-coverage my-gis-dataset "C_M_15_24"  male-15-24
  gis:apply-coverage my-gis-dataset "C_F_15_24" female-15-24
  gis:apply-coverage my-gis-dataset "C_M_25_59" male-25-59
  gis:apply-coverage my-gis-dataset "C_F_25_59" female-25-59
  gis:apply-coverage my-gis-dataset "C_M_60"    male-60
  gis:apply-coverage my-gis-dataset "C_F_60"    female-60

  gis:apply-coverage my-gis-dataset "P_LOW"  plow
  gis:apply-coverage my-gis-dataset "P_MED"  pmed
  gis:apply-coverage my-gis-dataset "P_HIGH" phigh

  ;Fill the Ploygon with color
  foreach gis:feature-list-of my-gis-dataset
  [
    feature ->
    if gis:property-value feature "ctype" = 1 [ gis:set-drawing-color red    gis:fill feature 2.0] ;low
    if gis:property-value feature "ctype" = 2 [ gis:set-drawing-color blue   gis:fill feature 2.0] ;mid
    if gis:property-value feature "ctype" = 3 [ gis:set-drawing-color green  gis:fill feature 2.0] ;high
  ]

  ;Identify Polygon wit ID number
  let x 1
  foreach gis:feature-list-of my-gis-dataset
  [
    feature ->
    let center-point gis:location-of gis:centroid-of feature
    let x-coordinate item 0 center-point
    let y-coordinate item 1 center-point

    ask patch x-coordinate y-coordinate[
      set PID x
      set centroid? true
    ]

    ask patches [
      if gis:intersects? feature self  [
      ;if gis:intersects? feature (list pxcor pycor) [
        set PID x
      ]
    ]

    set x x + 1
   ]
end


to initilize-population
  show "loading population"

  ;; set global here to make sure it is read correctly
  set scaling-factor scale-population ; input from interface

  ;1:100 1 agent 100 people rounded
  ask patches with [PID > 0] [set occupied? false ]
  let y 1
  while [y <= 23] [
    let ctype1 [community-social-type] of patches with  [centroid? = true and PID = y]
    ;create population based on age
    let m1524  [male-15-24]  of patches with [centroid? = true and PID = y]
    let f1524  [female-15-24]   of patches with [centroid? = true and PID = y]
    let m2459  [male-25-59]   of patches with [centroid? = true and PID = y]
    let f2459  [female-25-59]   of patches with [centroid? = true and PID = y]
    let m60    [male-60]   of patches with [centroid? = true and PID = y]
    let f60    [female-60]   of patches with [centroid? = true and PID = y]

    if ctype1 = [1][
      ;show "c1"
      ask patches with [PID = y and occupied? = false and centroid? = true][
        ;show PID
        let z 1
        ; TESTING ONLY
        ; cut the population in 2 to allow for analysis. Otherwise, the adjacency matrix
        ; gets over 16k columns and cannot be opened in Excel.
        let a item 0  m1524 / scaling-factor
        let b item 0  f1524 / scaling-factor
        let c item 0  m2459 / scaling-factor
        let d item 0  f2459 / scaling-factor
        let f item 0  m60 / scaling-factor
        let g item 0  f60 / scaling-factor

        while [z <= a][sprout 1[
          set breed people
          set hID z
          set h-social-type  0
          set hPoly y
          set shape "dot"
          ;set hIncome 0 + random int 10
          set color white
          set size 1
          set age (15 + random 10)
          set gender 1
          ask patch-here[set occupied? true]
          set z z + 1
        ]]
          while [z <= a + b][sprout 1[
            set breed people
            set hID z
            set h-social-type  0
            set hPoly y
            set shape "dot"
            ;set hIncome 10 + random int 5
            set color white
            set size 1
            set age (15 + random 10)
            set gender 2
            ask patch-here[set occupied? true]
            set z z + 1
          ]]

          while [z <= a + b + c][sprout 1[
            set breed people
            set hID z
            set h-social-type  0
            set hPoly y
            set shape "dot"
            ;set hIncome 15 + random int 10
            set color white
            set size 1
            set age (25 + random 35)
            set gender 1
            ask patch-here[set occupied? true]
            set z z + 1
          ]]

          while [z <= a + b + c + d][sprout 1[
            set breed people
            set hID z
            set h-social-type  0
            set hPoly y
            set shape "dot"
            ;set hIncome 25 + random int 10
            set color white
            set size 1
            set age (25 + random 35)
            set gender 2
            ask patch-here[set occupied? true]
            set z z + 1
          ]]

          while [z <= a + b + c + d + f][sprout 1[
            set breed people
            set hID z
            set h-social-type  0
            set hPoly y
            set shape "dot"
            ;set hIncome 25 + random int 10
            set color white
            set size 1
            set age (60 + random 10)
            set gender 1
            ask patch-here[set occupied? true]
            set z z + 1
          ]]

          while [z <= a + b + c + d + f + g][sprout 1[
            set breed people
            set hID z
            set h-social-type 0
            set hPoly y
            set shape "dot"
            ;set hIncome 35 + random int 15
            set color white
            set size 1
            set age (60 + random 10)
            set gender 2
            ask patch-here[set occupied? true]
            set z z + 1
          ]]

      ]
    ]
    if ctype1 = [2][
      ;show "c2"
      ask patches with [PID = y and occupied? = false and centroid? = true][
        ;show PID
        let z 1

        let a item 0  m1524 / scaling-factor
        let b item 0  f1524 / scaling-factor
        let c item 0  m2459 / scaling-factor
        let d item 0  f2459 / scaling-factor
        let f item 0  m60 / scaling-factor
        let g item 0  f60 / scaling-factor

        while [z <= a][sprout 1[
          set breed people
          set hID z
          set h-social-type  0
          set hPoly y
          set shape "dot"
          ;set hIncome 0 + random int 10
          set color white
          set size 1
          set age (15 + random 10)
          set gender 1
          ask patch-here[set occupied? true]
          set z z + 1
      ]]

          while [z <= a + b][sprout 1[
            set breed people
            set hID z
            set h-social-type  0
            set hPoly y
            set shape "dot"
            ;set hIncome 10 + random int 5
            set color white
            set size 1
            set age (15 + random 10)
            set gender 2
            ask patch-here[set occupied? true]
            set z z + 1
          ]]

          while [z <= a + b + c][sprout 1[
            set breed people
            set hID z
            set h-social-type  0
            set hPoly y
            set shape "dot"
            ;set hIncome 15 + random int 10
            set color white
            set size 1
            set age (25 + random 35)
            set gender 1
            ask patch-here[set occupied? true]
            set z z + 1
          ]]

          while [z <= a + b + c + d][sprout 1[
            set breed people
            set hID z
            set h-social-type  0
            set hPoly y
            set shape "dot"
            ;set hIncome 25 + random int 10
            set color white
            set size 1
            set age (25 + random 35)
            set gender 2
            ask patch-here[set occupied? true]
            set z z + 1
          ]]

          while [z <= a + b + c + d + f][sprout 1[
            set breed people
            set hID z
            set h-social-type  0
            set hPoly y
            set shape "dot"
            ;set hIncome 25 + random int 10
            set color white
            set size 1
            set age (60 + random 10)
            set gender 1
            ask patch-here[set occupied? true]
            set z z + 1
          ]]

          while [z <= a + b + c + d + f + g][sprout 1[
            set breed people
            set hID z
            set h-social-type  0
            set hPoly y
            set shape "dot"
            ;set hIncome 35 + random int 15
            set color white
            set size 1
            set age (60 + random 10)
            set gender 2
            ask patch-here[set occupied? true]
            set z z + 1
          ]]

      ]
    ]
    if ctype1 = [3][
      ;show "c3"
      ask patches with [PID = y and occupied? = false and centroid? = true][
        ;show PID
        let z 1

        let a item 0  m1524 / scaling-factor ; Está dividido entre 10 para correrlo con menos gente y poder hacer pruebas más rápido
        let b item 0  f1524 / scaling-factor
        let c item 0  m2459 / scaling-factor
        let d item 0  f2459 / scaling-factor
        let f item 0  m60 / scaling-factor
        let g item 0  f60 / scaling-factor

        while [z <= a][sprout 1[
          set breed people
          set hID z
          set h-social-type  0
          set hPoly y
          set shape "dot"
          ;set hIncome 0 + random int 10
          set color white
          set size 1
          set age (15 + random 10)
          set gender 1
          ask patch-here[set occupied? true]
          set z z + 1
      ]]

          while [z <= a + b][sprout 1[
            set breed people
            set hID z
            set h-social-type  0
            set hPoly y
            set shape "dot"
            ;set hIncome 10 + random int 5
            set color white
            set size 1
            set age (15 + random 10)
            set gender 2
            ask patch-here[set occupied? true]
            set z z + 1
          ]]

          while [z <= a + b + c][sprout 1[
            set breed people
            set hID z
            set h-social-type  0
            set hPoly y
            set shape "dot"
            ;set hIncome 15 + random int 10
            set color white
            set size 1
            set age (25 + random 35)
            set gender 1
            ask patch-here[set occupied? true]
            set z z + 1
          ]]

          while [z <= a + b + c + d][sprout 1[
            set breed people
            set hID z
            set h-social-type  0
            set hPoly y
            set shape "dot"
            ;set hIncome 25 + random int 10
            set color white
            set size 1
            set age (25 + random 35)
            set gender 2
            ask patch-here[set occupied? true]
            set z z + 1
          ]]

          while [z <= a + b + c + d + f][sprout 1[
            set breed people
            set hID z
            set h-social-type  0
            set hPoly y
            set shape "dot"
            ;set hIncome 25 + random int 10
            set color white
            set size 1
            set age (60 + random 10)
            set gender 1
            ask patch-here[set occupied? true]
            set z z + 1
          ]]

          while [z <= a + b + c + d + f + g][sprout 1[
            set breed people
            set hID z
            set h-social-type  0
            set hPoly y
            set shape "dot"
            ;set hIncome 35 + random int 15
            set color white
            set size 1
            set age (60 + random 10)
            set gender 2
            ask patch-here[set occupied? true]
            set z z + 1
          ]]

      ]
    ]
     set y y + 1
    ]
  ;3 set up the social network base on the type of agent

  ;
end


to set-h-social-type
  show "seting up social type"
  ;;loop through the shp caultate
  let y 1
  while [y <= 23] [
    ask patches with [PID = y][
      ;empolyment
      let people-count count people-here
      if people-count > 0 [
        let low  [plow] of patches with  [centroid? = true and PID = y]
        let med  [pmed] of patches with  [centroid? = true and PID = y]

        let per-low precision (item 0 low) 2
        show per-low
        if per-low != 0[
          ask n-of (round (people-count * per-low)) people with [h-social-type = 0] [set h-social-type  1]
        ]
        let per-med precision (item 0 med) 2
        show per-med
        if per-med != 0[
          ask n-of (round (people-count * per-med)) people with [h-social-type = 0] [set h-social-type 2]
        ]
        ;ask n-of (round (people-count * tempune)) households [set employed?  false]
      ]
    ]
    set y y + 1
  ]
  ask people with [h-social-type = 0] [set h-social-type 3]
end


to distribute-people ; move genratend gents witin their community
  ask people[
    ;show hpoly
    let poly-in hpoly
    move-to one-of patches with [pid = poly-in]
    set home-location patch-here
    set arrived? false ; make sure we set up whether people are at home or not
  ]
end

to set-destination
  print "set destination"
  ;community-list list []
  ;let community-list (range 1 23)
  ;print item 0 community-list
  ;print item 21 community-list
  ;print item 20 community-list
  ask people [
    set destination-community 0
  ]

  ;dest-possi list [] 2, 3, 22 most reip to these three destination
  ; refined to use real data. Source: https://rpubs.com/juan_raigoso/1176374

;CHECK THIS AND USE THE % FROM THE SHP FILE
  ask people [
  let options random-float 1
    (ifelse
      options <= 0.0084 [set destination-community	1 ]
      options <= 0.1788 [set destination-community	2 ]
      options <= 0.3091 [set destination-community	3 ]
      options <= 0.3767 [set destination-community	4 ]
      options <= 0.3966 [set destination-community	5 ]
      options <= 0.4223 [set destination-community	6 ]
      options <= 0.4493 [set destination-community	7 ]
      options <= 0.4868 [set destination-community	8 ]
      options <= 0.5344 [set destination-community	9 ]
      options <= 0.5679 [set destination-community	10 ]
      options <= 0.5897 [set destination-community	11 ]
      options <= 0.5990 [set destination-community	12 ]
      options <= 0.6243 [set destination-community	13 ]
      options <= 0.6386 [set destination-community	14 ]
      options <= 0.6603 [set destination-community	15 ]
      options <= 0.6894 [set destination-community	16 ]
      options <= 0.7623 [set destination-community	17 ]
      options <= 0.7861 [set destination-community	18 ]
      options <= 0.8963 [set destination-community	19 ]
      options <= 0.9100 [set destination-community	20 ]
      options <= 0.9296 [set destination-community	21 ]
      [set destination-community	22 ])

    let target-community destination-community
    let matching-patches patches with [CID = target-community]
    set workplace one-of matching-patches
    face workplace

    set dist-home-work (distance workplace)


  ]

 ; ask n-of (0.6 * count people) people [
   ; let options [2 3 22]
  ;  set destination-community one-of options
  ;]

  ;ask people with [destination-community = 0] [
   ; let options [1 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21]
    ;set destination-community one-of options]
end

to set-transportation-type
  ask people [set t-type 0]

  show "setting up trasportation"
  ; set up motor based on the real r
  ; the rest of the people will be 40:39:21 as cars:public:cycle
  ;male
  ask n-of (round count people with [h-social-type = 1 and gender = 1] * 0.13) people with [h-social-type = 1 and gender = 1 and t-type = 0][
    set t-type 1 ;car

  ]

  ask n-of (round count people with [h-social-type = 1 and gender = 1] * 0.40) people with [h-social-type = 1 and gender = 1 and t-type = 0][
    set t-type 2 ;moto

  ]

  ask n-of (round count people with [h-social-type = 1 and gender = 1] * 0.47) people with [h-social-type = 1 and gender = 1 and t-type = 0][
    set t-type 3 ;bus

  ]

  ask n-of (round count people with [h-social-type = 2 and gender = 1] * 0.47) people with [h-social-type = 2 and gender = 1 and t-type = 0][
    set t-type 1 ;cars

  ]
  ask n-of (round count people with [h-social-type = 2 and gender = 1] * 0.25) people with [h-social-type = 2 and gender = 1 and t-type = 0][
    set t-type 2 ;moto
    ;set the trasportation type then set other attrubute based on the type (motor, car, public)

  ]
  ask n-of (round count people with [h-social-type = 2 and gender = 1] * 0.28) people with [h-social-type = 2 and gender = 1 and t-type = 0][
    set t-type 3 ;bus

  ]
  ask n-of (round count people with [h-social-type = 3 and gender = 1] * 0.83) people with [h-social-type = 3 and gender = 1 and t-type = 0][
    set t-type 1 ;cars

  ]
  ask n-of (round count people with [h-social-type = 3 and gender = 1] * 0.07) people with [h-social-type = 3 and gender = 1 and t-type = 0][
    set t-type 2 ;moto
    ;set the trasportation type then set other attrubute based on the type (motor, car, public)

  ]
  ask n-of (round count people with [h-social-type = 3 and gender = 1] * 0.10) people with [h-social-type = 3 and gender = 1 and t-type = 0][
    set t-type 3 ;bus

  ]

  ;female
   ask n-of (round count people with [h-social-type = 1 and gender = 2] * 0.12) people with [h-social-type = 1 and gender = 2 and t-type = 0][
    set t-type 1 ;cars

  ]
  ask n-of (round count people with [h-social-type = 1 and gender = 2] * 0.29) people with [h-social-type = 1 and gender = 2 and t-type = 0][
    set t-type 2 ;moto
    ;set the trasportation type then set other attrubute based on the type (motor, car, public)

  ]
  ask n-of (round count people with [h-social-type = 1 and gender = 2] * 0.59) people with [h-social-type = 1 and gender = 2 and t-type = 0][
    set t-type 3 ;bus

  ]

  ask n-of (round count people with [h-social-type = 2 and gender = 2] * 0.51) people with [h-social-type = 2 and gender = 2 and t-type = 0][
    set t-type 1 ;cars

  ]
  ask n-of (round count people with [h-social-type = 2 and gender = 2] * 0.18) people with [h-social-type = 2 and gender = 2 and t-type = 0][
    set t-type 2 ;moto
    ;set the trasportation type then set other attrubute based on the type (motor, car, public)

  ]
  ask n-of (round count people with [h-social-type = 2 and gender = 2] * 0.31) people with [h-social-type = 2 and gender = 2 and t-type = 0][
    set t-type 3 ;bus

  ]

  ask n-of (round count people with [h-social-type = 3 and gender = 2] * 0.90) people with [h-social-type = 3 and gender = 2 and t-type = 0][
    set t-type 1 ;cars

  ]
  ask n-of (round count people with [h-social-type = 3 and gender = 2] * 0.03) people with [h-social-type = 3 and gender = 2 and t-type = 0][
    set t-type 2 ;moto
    ;set the trasportation type then set other attrubute based on the type (motor, car, public)

  ]
  ask n-of (round count people with [h-social-type = 3 and gender = 2] * 0.07) people with [h-social-type = 3 and gender = 2 and t-type = 0][
    set t-type 3 ;bus

  ]

  let mode-prob random-float 1

  ask people with [t-type = 0]
[

  ifelse mode-prob <= 0.4  [set t-type 1]
          [ifelse mode-prob <= 0.25 [set t-type 2]
              [set t-type 3]]

  ]


  ask people
  [set-transportation-info-based-on-type]

end

to set-uncertainty-threshold ; level of uncertainty regarding the transport mode that is accepted by people

  ask people with [t-type = 1]
  [
    let uncertm -1
    while [uncertm < 0 or uncertm > 1]
     [
      set uncertm random-normal Uncert-m (Uncert-m * deviation)
     ]
 ;   show uncertm
       set uncertainty-threshold uncertm
  ]

 ask people with [t-type = 2]
  [
    let uncertc -1
    while [uncertc < 0 or uncertc > 1]
     [
      set uncertc random-normal Uncert-c (Uncert-c * deviation)
     ]
    ;show uncertc
       set uncertainty-threshold uncertc
   ]


 ask people with [t-type = 3]
  [
    let uncertp -1
    while [uncertp < 0 or uncertp > 1]
     [
      set uncertp random-normal Uncert-p (Uncert-p * deviation)
     ]
   ; show uncertp
       set uncertainty-threshold uncertp
  ]


end

to set-satisfaction-threshold ; level of satisfaction that people would like to have with their transport mode ;

  ask people with [t-type = 1]
  [
    let satisfactm -1
    while [satisfactm < 0 or satisfactm > 1]
     [
      set satisfactm random-normal Satisf-m (Satisf-m * deviation)
     ]
   ; show satisfactm
       set satisfaction-threshold satisfactm
  ]

    ask people with [t-type = 2]
  [
    let satisfactc -1
    while [satisfactc < 0 or satisfactc > 1]
     [
      set satisfactc random-normal Satisf-c (Satisf-c * deviation)
     ]
  ;  show satisfactc
       set satisfaction-threshold satisfactc
  ]


    ask people with [t-type = 3]
  [
    let satisfactp -1
    while [satisfactp < 0 or satisfactp > 1]
     [
      set satisfactp random-normal Satisf-p (Satisf-p * deviation)
     ]
  ;  show satisfactp
       set satisfaction-threshold satisfactp
  ]


end


to set-weights ; level of importance that people give to the transportation attibutes according their socio-economic situation

 ; assigns points for each atribute in low socio-economic status
   ask people with [h-social-type = 1 ]
    [weights-socio-1]
 ; assigns points for each atribute in middle socio-economic status
   ask people with [h-social-type = 2 ]
    [weights-socio-2]
 ; assigns points to people in high socio-economic status
   ask people with [h-social-type = 3 ]
    [weights-socio-3]


end

to weights-socio-1


   ; Weights for low-income people
  set p-buy first (item 29 my-csv-dataset)
  set p-ope first (item 30 my-csv-dataset)
  set p-saf first (item 31 my-csv-dataset)
  set p-sec first (item 32 my-csv-dataset)
  set p-com first (item 33 my-csv-dataset)
  set p-tim first (item 34 my-csv-dataset)
  set p-pol first (item 35 my-csv-dataset)

    ; assigns points with a normal distribution for each attribute
    let points-buy -1
    while [points-buy < 0 or points-buy > 100]
     [set points-buy random-normal p-buy (p-buy * 0.1)]

    let points-ope -1
    while [points-ope < 0 or points-ope > 100]
     [set points-ope random-normal p-ope (p-ope * 0.1)]

    let points-saf -1
     while [points-saf < 0 or points-saf > 100]
    [set points-saf random-normal p-saf (p-saf * 0.1)]

    let points-sec -1
    while [points-sec < 0 or points-sec > 100]
     [set points-sec random-normal p-sec (p-sec * 0.1)]

    let points-com -1
    while [points-com < 0 or points-com > 100]
     [set points-com random-normal p-com (p-com * 0.1)]

    let points-tim -1
    while [points-tim < 0 or points-tim > 100]
     [set points-tim random-normal p-tim (p-tim * 0.1)]

    let points-pol -1
    while [points-pol < 0 or points-pol > 100]
     [set points-pol random-normal p-pol (p-pol * 0.1)]

    ; converts points in percentages
    let pointstotal points-buy + points-ope + points-saf + points-sec + points-com + points-tim + points-pol

    set w-buy (points-buy / pointstotal)
    set w-ope (points-ope / pointstotal)
    set w-saf (points-saf / pointstotal)
    set w-sec (points-sec / pointstotal)
    set w-com (points-com / pointstotal)
    set w-tim (points-tim / pointstotal)
    set w-pol (points-pol / pointstotal)

 end

to weights-socio-2


 ; Weights for middle-income people
  set p-buy2 first (item 36 my-csv-dataset)
  set p-ope2 first (item 37 my-csv-dataset)
  set p-saf2 first (item 38 my-csv-dataset)
  set p-sec2 first (item 39 my-csv-dataset)
  set p-com2 first (item 40 my-csv-dataset)
  set p-tim2 first (item 41 my-csv-dataset)
  set p-pol2 first (item 42 my-csv-dataset)

    ; assigns points with a normal distribution for each attribute
    let points-buy2 -1
    while [points-buy2 < 0 or points-buy2 > 100]
     [set points-buy2 random-normal p-buy2 (p-buy2 * 0.1)]

    let points-ope2 -1
    while [points-ope2 < 0 or points-ope2 > 100]
     [set points-ope2 random-normal p-ope2 (p-ope2 * 0.1)]

    let points-saf2 -1
    while [points-saf2 < 0 or points-saf2 > 100]
     [set points-saf2 random-normal p-saf2 (p-saf2 * 0.1)]

    let points-sec2 -1
    while [points-sec2 < 0 or points-sec2 > 100]
     [set points-sec2 random-normal p-sec2 (p-sec2 * 0.1)]

    let points-com2 -1
    while [points-com2 < 0 or points-com2 > 100]
     [set points-com2 random-normal p-com2 (p-com2 * 0.1)]

    let points-tim2 -1
    while [points-tim2 < 0 or points-tim2 > 100]
     [set points-tim2 random-normal p-tim2 (p-tim2 * 0.1)]

    let points-pol2 -1
    while [points-pol2 < 0 or points-pol2 > 100]
     [set points-pol2 random-normal p-pol2 (p-pol2 * 0.1)]

    ; converts points in percentages
    let pointstotal2 points-buy2 + points-ope2 + points-saf2 + points-sec2 + points-com2 + points-tim2 + points-pol2

    set w-buy (points-buy2 / pointstotal2)
    set w-ope (points-ope2 / pointstotal2)
    set w-saf (points-saf2 / pointstotal2)
    set w-sec (points-sec2 / pointstotal2)
    set w-com (points-com2 / pointstotal2)
    set w-tim (points-tim2 / pointstotal2)
    set w-pol (points-pol2 / pointstotal2)

 end

to weights-socio-3


 ; Weights for high-income people
  set p-buy3 first (item 43 my-csv-dataset)
  set p-ope3 first (item 44 my-csv-dataset)
  set p-saf3 first (item 45 my-csv-dataset)
  set p-sec3 first (item 46 my-csv-dataset)
  set p-com3 first (item 47 my-csv-dataset)
  set p-tim3 first (item 48 my-csv-dataset)
  set p-pol3 first (item 49 my-csv-dataset)

    ; assigns points with a normal distribution for each attribute
    let points-buy3 -1
    while [points-buy3 < 0 or points-buy3 > 100]
     [set points-buy3 random-normal p-buy3 (p-buy3 * 0.1)]

    let points-ope3 -1
    while [points-ope3 < 0 or points-ope3 > 100]
     [set points-ope3 random-normal p-ope3 (p-ope3 * 0.1)]

    let points-saf3 -1
    while [points-saf3 < 0 or points-saf3 > 100]
     [set points-saf3 random-normal p-saf3 (p-saf3 * 0.1)]

    let points-sec3 -1
    while [points-sec3 < 0 or points-sec3 > 100]
     [set points-sec3 random-normal p-sec3 (p-sec3 * 0.1)]

    let points-com3 -1
    while [points-com3 < 0 or points-com3 > 100]
     [set points-com3 random-normal p-com3 (p-com3 * 0.1)]

    let points-tim3 -1
    while [points-tim3 < 0 or points-tim3 > 100]
     [set points-tim3 random-normal p-tim3 (p-tim3 * 0.1)]

    let points-pol3 -1
    while [points-pol3 < 0 or points-pol3 > 100]
     [set points-pol3 random-normal p-pol3 (p-pol3 * 0.1)]

    ; converts points in percentages
    let pointstotal3 points-buy3 + points-ope3 + points-saf3 + points-sec3 + points-com3 + points-tim3 + points-pol3

    set w-buy (points-buy3 / pointstotal3)
    set w-ope (points-ope3 / pointstotal3)
    set w-saf (points-saf3 / pointstotal3)
    set w-sec (points-sec3 / pointstotal3)
    set w-com (points-com3 / pointstotal3)
    set w-tim (points-tim3 / pointstotal3)
    set w-pol (points-pol3 / pointstotal3)

end



to set-speed

  let average-speed-m first (item 0 my-csv-dataset)
  let average-speed-c first (item 1 my-csv-dataset)
  let average-speed-p first (item 2 my-csv-dataset)

  ;show average-speed-m
  ;show average-speed-c
  ;show average-speed-p

  ask people [
    set speed-m random-normal average-speed-m (average-speed-m * 0.1)
    set speed-c random-normal average-speed-c (average-speed-c * 0.1)
    set speed-p random-normal average-speed-p (average-speed-p * 0.1)
   ]



end

to set-transportation-info-based-on-type


 ; Asignation of initial scores (0 - 1) to the acquisition cost for each transport mode
  set cost-buy-mot first (item 3 my-csv-dataset)
  set cost-buy-car first (item 4 my-csv-dataset)
  set cost-buy-pub first (item 5 my-csv-dataset)

; Asignation of initial scores (0 - 1) to the operation fixed cost for each transport mode
  set costf-op-mot first (item 6 my-csv-dataset)
  set costf-op-car first (item 7 my-csv-dataset)
  set costf-op-pub first (item 8 my-csv-dataset)

; Asignation of initial scores (0-1) to the comfort for each transport mode
  set comfort-m first (item 9 my-csv-dataset)
  set comfort-c first (item 10 my-csv-dataset)
  set comfort-p first (item 11 my-csv-dataset)

; Gasoline price USD
  set gas-price first (item 12 my-csv-dataset);

; Efficiency of transport mode km/gal
  set eff-mot first (item 13 my-csv-dataset)
  set eff-car first (item 14 my-csv-dataset)

; Emissions
  set emi-mot first (item 15 my-csv-dataset)
  set emi-car first (item 16 my-csv-dataset)
  set emi-pub first (item 17 my-csv-dataset)

; Accident rate
  set acc-rate-mot first (item 18 my-csv-dataset)
  set acc-rate-car first (item 19 my-csv-dataset)
  set acc-rate-pub first (item 20 my-csv-dataset)

; Insecurity rates of transport modes
  set insecur-m first (item 21 my-csv-dataset)
  set insecur-c first (item 22 my-csv-dataset)
  set insecur-p first (item 23 my-csv-dataset)

; Cost Increments
  set buy-increase-m first (item 24 my-csv-dataset)
  set buy-increase-c first (item 25 my-csv-dataset)


end


;;************************;;
;;****2 Main Functions****;;
;;************************;;

;each time step the model will run the go function
to go

  ;; VIDEO RECORDING SETUP
  if vid:recorder-status = "inactive" [
    vid:start-recorder
  ]
  ;; CAPTURE THE CURRENT FRAME
  ;; Recording twice to "slow down" the video
  vid:record-view
  vid:record-view

  ;2 set up the transportation type
  ;stay the same
  ;change

  ;3 check the condition to move?
  ;3,1 update some varibales
  ;
  commute
  update-safety
  update-security
  update-time

  if ticks > 1
  [

    if ticks mod (30) = 0 ; every 30 ticks represent a peak hour in a typical day of a year. People make decision every year (every 30 ticks).
                          ; procedures that run every decision period
    [
      update-scores-tech-attributes ; calulates values for tech attributes to be used in satisfaction update for each agent in every decision tick
      update-satisfaction    ; updates values of satisfcation for each agent in every tick
      update-experience      ; number of times that a person has chosen every transport mode over the time steps
      update-uncertainty     ; updates uncertainty level for each agent in every tick
      update-type-choice     ; according to satisfaction and uncertainty applies the decision making rule
      ask people [move-to home-location set arrived? false]
    ]

    if ticks mod 30 = 1
    ; procedures that run at the beggining of the new decision period
    [
      choice                 ; Breaks population into groups according to their type of choice: "repetition", "imitation", "deliberation", "inquiring"
      update-age-people      ; updates people age
                             ;update-ownership      ; updates car or motrocycle ownership depending on mode choice
    ]
    ;; SAVE FINAL VIDEO
    if ticks = (Time-steps * 30 + 2)
    [
      vid:save-recording "cali_sim.mp4"
      print vid:recorder-status
      stop
    ]

  ]

  tick

end



to commute

  ask people with [not arrived?] ; only run the step for people who are still travelling
  [
    let near-people people-on (patch-set patch-here neighbors)
    let people-around near-people with [not arrived?]; only count people who are not already at work

    let cars count people-around with [t-type = 1]
    let mot-equiv-car (count people-around with [t-type = 2]) * 0.5
    let pub-equiv-car (count people-around with [t-type = 3]) * 0.05

    ;let cars             (count people-here with [t-type = 2]) + (sum [count people-here with [t-type = 2]] of neighbors)          ; neighbors corresponds to the agentset containing the 8 surrounding patches (9 including it self). It is a patch primitive, thats why it's needed to ad people-here of neighbors
    ;let mot-equiv-car  (((count people-here with [t-type = 1]) + (sum [count people-here with [t-type = 1]] of neighbors)) * 0.5) ; 2 motorcycles equivalent
    ;let pub-equiv-car  (((count people-here with [t-type = 3]) + (sum [count people-here with [t-type = 3]] of neighbors)) * 0.05) ; 20 people in 1 bus - UPDATE WHEN FREQUENCY INCREASE

    let equiv-cars (cars + mot-equiv-car + pub-equiv-car)
   ; set density (equiv-cars * scaling-factor / 2) ; using adjusted number
    set density (0.1 * equiv-cars * (20000 / count people) ) ; DENSITY SHOULD BE THE NUMBER OF CARS ON ROADS DIVIDED THE "CAPACITY" OF THE ROAD, I'M CALCULATING IT AS THE NUMBER OF PEOPLE PER PATCH * X TIMES


 ; effect of road accidents

    ; should we only count accidents on the original patch?
    let accidents-nearby (count people-around with [safety = 1]) ; + (sum [count people-here with [safety = 1]] of neighbors))
    let accident-congestion 1
     if accidents-nearby > 0
      [set accident-congestion 0.8]  ; factor that reduces the speed representing the effect of an accident on the road

    let factor 1 ; Initialization of speed factor

    if density > 0.5 [set factor 0.95]
    if density > 1   [set factor 0.90]
    if density > 1.5 [set factor 0.85]
    if density > 2   [set factor 0.80]
    if density > 2.5 [set factor 0.75]
    if density > 3   [set factor 0.70]
    if density > 3.5 [set factor 0.65]
    if density > 4   [set factor 0.60]
    if density > 4.5 [set factor 0.55]
    ; added additional density
    if density > 5 [set factor 0.50]
    if density > 6 [set factor 0.45]
    if density > 7 [set factor 0.40]
    if density > 8 [set factor 0.35]
    if density > 9 [set factor 0.30]
    if density > 10 [set factor 0.25]
    if density > 12 [set factor 0.20]

; effect of congestion

       set speed-mot ((speed-m * factor ) * accident-congestion )
       set speed-car ((speed-c * factor ) * accident-congestion )
       set speed-pub ((speed-p * factor ) * accident-congestion )


    ;
     if t-type = 1 [set speed speed-car]
     if t-type = 2 [set speed speed-mot]
     if t-type = 3 [set speed speed-pub]

        (ifelse
        factor * accident-congestion < 0.25
        [ set color red ]
        factor * accident-congestion < 0.50
        [ set color orange + 1 ]
        factor * accident-congestion < 0.75
        [ set color yellow + 2 ]
        ; else...
        [ set color white ])

    if safety = 1
    [
      set color magenta + 2
    ]

  let start-x xcor
  let start-y ycor

  ifelse distance workplace > (1 * speed)
   [fd 1 * speed]
   [move-to workplace set color black set arrived? true]

; calculate distance traveled

 set dist-trip distancexy start-x start-y
 set kms ((distance home-location)) ; Note1: where are use these two varibales used in the model, do we need this?

  ]


end


; SAFETY CALCULATION EVERY TICK
to update-safety

  ; Resets accidents every tick
  ;ask people [set safety 0]

  ; Resets the accident count in the system for agents for the new decision period
  if (ticks mod 30) = 1
  [
    set acc-mot-count 0
    set acc-car-count 0
    set acc-pub-count 0
    ask people [set safety 0]
  ]


 ; Probability of having road accidents
  ; car accidents
  ask people with [t-type = 1 and gender = 1 and not arrived?] ; young males are more prone to have accidents
  [
    let acc-prob-c random-float 1

    ifelse age < 35
    [if acc-prob-c <= (acc-rate-car * 1.3) [set safety 1]]
    [if acc-prob-c <= acc-rate-car         [set safety 1]] ;Note 2, the conditional operation is not correct somehow

      ;    ifelse ((acc-prob-c <= (acc-rate-car * 1.3)) and age < 35)  ; I LET THE INCREASE IN RATE FOR MALE AS IT WAS BEFORE THE METTING, BECAUSE IT SHOULD BE HIGHER FOR MEN ONLY IN THIS RANGE OF AGE. THE BASE WILL BE THE REST OF MEN AND FEMALE WILL HAVE A REDUCED RATE.
      ;    [set safety 1 ]
      ;    [
      ;      if (acc-prob-c <= (acc-rate-car)) ;Note 2, the conditional operation is not correct somehow
      ;      [set safety 1]
      ;    ]
    ]

    ask people with [t-type = 1 and gender = 2  and not arrived?]
    [
      if (random-float 1 <= (acc-rate-car * 0.5)) [set safety 1]; reduction in female rate was adjusted according to accident rates 2016-2023
    ]

    ; moto accidents
    ask people with [t-type = 2 and gender = 1 and not arrived?]
    [
      let acc-prob-m random-float 1
      ifelse ((acc-prob-m <= (acc-rate-mot * 1.3)) and age < 35 ) ; THE RATE FOR MEN USING MOTO IS ALSO HIGHER FOR THOSE BETWEEN 15-35
      [set safety 1 ] ; young males are more prone to have accidents
      [if (acc-prob-m <= acc-rate-mot)[set safety 1]]
    ]

    ask people with [t-type = 2 and gender = 2 and not arrived?]
    [
      if (random-float 1 <= (acc-rate-mot * 0.7)) ;reduction in female rate was adjusted according to accident rates 2016-2023
      [set safety 1]
    ]

    ; public accidents ;Note3 should the acc rate of public transportation be divided by the people in the public vehicle?
    ask people with [t-type = 3  and not arrived?]
    [if random-float 1 <= acc-rate-pub [set safety 1]]

;    ; Counts road accidents by mode in the system
;    let acc-car count people with [t-type = 1 and safety = 1]
;    let acc-mot count people with [t-type = 2 and safety = 1]
;    let acc-pub count people with [t-type = 3 and safety = 1]

    ; Accumulates accidents during the commuting periods; Note 4: is the actual number of accident from the simulation realistic? ask the people that are not in the accident
    set acc-car-count count people with [t-type = 1 and safety = 1]
    set acc-mot-count count people with [t-type = 2 and safety = 1]
    set acc-pub-count count people with [t-type = 3 and safety = 1]

end



; SECURITY CALCULATION AT EVERY TICK
to update-security

 ; Resets incidents every tick
  ;Note6 do you think this should work as the safety function?
 ; ask people [set security 0] ;Security = 0 means no incidents.

  if (ticks mod 30) = 1

  ; Resets the total incident count in the system for the new decision period
  [ set inc-mot-count 0
    set inc-car-count 0
    set inc-pub-count 0
    ; Resets the incident count
    ask people
    [
      ; Resets the incident count in the network for the new decision period
      set inc-nw-m-count 0
      set inc-nw-c-count 0
      set inc-nw-p-count 0
      set security 0
    ]

  ]


 ; Probability of having personal security incidents
  ask people with [t-type = 1 and not arrived?]
    [if random-float 1 <= insecur-c [set security 1]]

  ask people with [t-type = 2 and not arrived?]
    [if random-float 1 <= insecur-m [set security 1]]

  ask people with [t-type = 3 and not arrived?]
    [if random-float 1 <= insecur-p [set security 1]]

 ; Checks if people in the network have experienced insecurity incidents
  ask people
   [
      set inc-nw-m-count count link-neighbors with [t-type = 1 and security = 1]
      set inc-nw-m-count count link-neighbors with [t-type = 2 and security = 1]
      set inc-nw-p-count count link-neighbors with [t-type = 3 and security = 1]


;      let inc-nw-c count link-neighbors with [t-type = 1 and security = 1]
;      let inc-nw-m count link-neighbors with [t-type = 2 and security = 1]
;      let inc-nw-p count link-neighbors with [t-type = 3 and security = 1]
;
;      ; Accumulates incidents by mode in the network
;      set inc-nw-m-count (inc-nw-m-count + inc-nw-m )
;      set inc-nw-c-count (inc-nw-c-count + inc-nw-c )
;      set inc-nw-p-count (inc-nw-p-count + inc-nw-p )

  ]


  ; Accumulates incidents in the system by decision period
  set inc-car-count count people with [security = 1 and t-type = 1]
  set inc-mot-count count people with [security = 1 and t-type = 2]
  set inc-pub-count count people with [security = 1 and t-type = 3]

;  ;Counts incidents in the system
;  let inc-car (count people with [security = 1 and t-type = 1] )
;  let inc-mot (count people with [security = 1 and t-type = 2] )
;  let inc-pub (count people with [security = 1 and t-type = 3] )

  ; Accumulates incidents in the system by decision period
;  set inc-mot-count (inc-mot-count + inc-mot)
;  set inc-car-count (inc-car-count + inc-car)
;  set inc-pub-count (inc-pub-count + inc-pub)


end

; TIME CALCULATION AT EVERY TICK

to update-time

  let bus-passengers (count people with [t-type = 3])
  let wait-turns (bus-passengers / capacity-public) ; indicates the number of turns people need to wait to catch a bus


  ask people
  [

    if (ticks mod 30) = 1
        [set time-m 0
          set time-c 0
          set time-p 0]

    let relative-speed (reg-speed-pub / speed-pub ) ; if current speed in the public system is lower than regular speed at the current capacity, people need to wait more
    set wait-time-p ((random-normal  default-wait-time  1) * relative-speed  * wait-turns)  ; default wait time with the expected congestion at peak hour affected by the difference in speed with the current situation
                                                                                            ;in the street multiplied by the number of turns passengers need to wait to catch a bus due to the congestion in the public system

    ; Calculation of accumulated time to calculate the average time of travel per decision period
    set time-m (time-m + dist-home-work / speed-mot / 100 * 60)
    set time-c (time-c + dist-home-work / speed-car / 100 * 60)  ;Note 7 why we are having this? since we should have this data in the peoples attribute
    set time-p (time-p + dist-home-work / speed-pub / 100 * 60 + wait-time-p)


    ; Updates time for people according to the transport mode
    if t-type = 1  [set time (time-c / 30)] ;"/30" calculates the average time to complete the commute home-work
    if t-type = 2  [set time (time-m / 30)]
    if t-type = 3  [set time (time-p / 30)]
  ]

end


to update-scores-tech-attributes

  ask people
  [

   ; UPDATE PRURCHASE COST SCORES
   set cost-buy-mot (cost-buy-mot * (1 - buy-increase-m) )
   set cost-buy-car (cost-buy-car * (1 - buy-increase-c) )

   ; UPDATE OPERATING COST SCORES
   ; show kms
   let effi-mot random-normal eff-mot (eff-mot * deviation * 2) ; efficiency of motorcycle (kms/galon) normally distributed for each agent
   let effi-car random-normal eff-car (eff-car * deviation * 2) ; efficiency of car (kms/galon) normally distributed for each agent
   set costv-mot (kms / effi-mot * gas-price)
   set costv-car (kms / effi-car * gas-price)
   ; show costv-mot
   ; show costv-car

  ]
  ; changed this to be outside of asking people, so we don't run this for every person - Max
   set max-costv max [costv-car] of people ; max variable operating cost in the system
   set min-costv min [costv-mot] of people ; min variable operating cost in the system


    ask people
  [
    ;show max-costv
    ;show min-costv

   set costv-op-mot (1 - ((costv-mot - min-costv) / (max-costv - min-costv))) ; standarization of cost to obtain a score
   set costv-op-car (1 - ((costv-car - min-costv) / (max-costv - min-costv))) ; standarization of cost to obtain a score

   let costv-op-pub 1 ; since public transit does not have variable costs, it has the highiest score
   let costfix-op-pub random-normal costf-op-pub deviation

   let sumcostop (costv-op-mot + costf-op-mot + costv-op-car + costf-op-car + costv-op-pub + costfix-op-pub) ;fixed cost scores come from the initial data

   set cost-op-mot ((costv-op-mot + costf-op-mot) / sumcostop)
   set cost-op-car ((costv-op-car + costf-op-car) / sumcostop)
  ; set cost-op-pub ((costv-op-pub + costf-op-pub) / sumcostop)
   set cost-op-pub costfix-op-pub

 ; UPDATE SAFETY SCORES according to total number of accidents by mode

   let sumacc (acc-mot-count + acc-car-count + acc-pub-count) ; Cumulative sum of accidents during the decision period

    ifelse sumacc > 0
    [

      set safety-mot (1 - (acc-mot-count / sumacc))
      set safety-car (1 - (acc-car-count / sumacc))
      set safety-pub (1 - (acc-pub-count / sumacc))
    ]
    [set safety-mot 1 set safety-car 1 set safety-pub 1 ] ;if sum-accident = 0, safety score has to be the highest (1)


; UPDATE SECURITY SCORES

; security scores based on incidents in the agent's network
    let sum-incident (inc-nw-m-count + inc-nw-c-count + inc-nw-p-count)
    ifelse sum-incident > 0
     [ set security-mot (1 - (inc-nw-m-count / sum-incident))
       set security-car (1 - (inc-nw-c-count / sum-incident))
       set security-pub (1 - (inc-nw-p-count / sum-incident))
     ]
     [ set security-mot 1 set security-car 1 set security-pub 1 ] ;if sum-incident = 0, security score has to be the highest (1)

 ; UPDATE POLLUTION SCORES (CO2 emissions)

    if t-type = 1
      [set pollution (kms * emi-car)]
    if t-type = 2
      [set pollution (kms * emi-mot)]
    if t-type = 3
      [set pollution (kms * emi-pub)]

  ]

    let emissions-car sum [pollution] of people with [t-type = 1]
    let emissions-mot sum [pollution] of people with [t-type = 2]
    let emissions-pub sum [pollution] of people with [t-type = 3]
    let sum-emissions (emissions-mot + emissions-car + emissions-pub) ; total emissions of the system

    let max-emi max (list emi-mot emi-car emi-pub)
    let tot-km sum [kms] of people
    let max-emissions (max-emi * tot-km) ; highest possible emissions of the system
    set pollution-tot (1 - (sum-emissions / max-emissions)) ; score of pollution. If sum-emissions = max-emissions, pollution-tot will be 0, meaning that there's no contribution in the satisfaction function (totally unsatisfied regarding pollution)


  ; UPDATE COMFORT SCORES

   ; Comfort score affected by random events (weather, mechanical failure) and saturation of public transit
  ask people [

    let prob-bad-weather  random-float 0.6     ; has impact on moto and public transit comfort

    ; Note: should this number be 0? Or something else? Density will never be less than 0
    ifelse density >= 0                        ; high congestion increases stress, decreasing comfort
     [
        set comfort-mot (comfort-m * (1 - prob-bad-weather) * (1 - density * 0.1))  ; bad weather and congestion have impact on mot comfort
        set comfort-car (comfort-c * (1 - density * 0.3))                           ; congestion has a higher impact on car comfort, bad weather does not affect car comfort
        set comfort-pub (comfort-p * (1 - prob-bad-weather) * (1 - density * 0.2))  ; bad weather and congestion have impact on public comfort
     ]
     [
      set comfort-mot (comfort-m * (1 - prob-bad-weather)) ; bad weather and congestion have impact on mot comfort
      set comfort-car (comfort-c) ; congestion has a higher impact on car comfort
      set comfort-pub (comfort-p * (1 - prob-bad-weather)) ; probability of mechanic-failure - probability of having bad weather
     ]


     if t-type = 1
      [set comfort comfort-car]
     if t-type = 2
      [set comfort comfort-mot]
     if t-type = 3
      [set comfort comfort-pub]
  ]

  ; UPDATE TIME SCORES

   ;calaculation of time score based on possible time with other modes


    let max-time max [time] of people    ; max time in the system
    let min-time min [time] of people    ; min time in the system

    ;show max-time

ask people [

    set time-mot (1 - ((time-m / 30 - min-time) / (max-time - min-time)))
    set time-car (1 - ((time-c / 30 - min-time) / (max-time - min-time)))
    set time-pub (1 - ((time-p / 30 - min-time) / (max-time - min-time)))

  ]

end


;;************************;;
;;****     3 Tools    ****;;
;;************************;;


to update-satisfaction
  ask people
   [
    set satisfaction-mot (w-buy * cost-buy-mot + w-ope * cost-op-mot + w-saf * safety-mot + w-sec * security-mot + w-com * comfort-mot + w-tim * time-mot + w-pol * pollution-tot)
    set satisfaction-car (w-buy * cost-buy-car + w-ope * cost-op-car + w-saf * safety-car + w-sec * security-car + w-com * comfort-car + w-tim * time-car + w-pol * pollution-tot)
    set satisfaction-pub (w-buy * cost-buy-pub + w-ope * cost-op-pub + w-saf * safety-pub + w-sec * security-pub + w-com * comfort-pub + w-tim * time-pub + w-pol * pollution-tot)
   ]

  ask people with [t-type = 1]
   [set satisfaction satisfaction-mot]
  ask people with [t-type = 2]
   [set satisfaction satisfaction-car]
  ask people with [t-type = 3]
   [set satisfaction satisfaction-pub]

end

to update-experience
 ask people
  [
   if t-type = 1 [set experience-mot experience-mot + 1]
   if t-type = 2 [set experience-car experience-car + 1]
   if t-type = 3 [set experience-pub experience-pub + 1]
  ]
end

to update-uncertainty

   ; Uncertainty Parameters to calculate experience
  set alpha first (item 50 my-csv-dataset)
  set beta  first (item 51 my-csv-dataset)

  ask people
  [
   ; calculates how many neihgbors have the same transport mode
    let mymode t-type
    set neighborsmymode count link-neighbors with [t-type = mymode]

   ; calculates the proportion of times that the selected mode has choosen during the simulation time
    ifelse t-type = 1
     [set experience experience-mot]
     [ifelse t-type = 2
      [set experience experience-car]
      [set experience experience-pub]]
    let myexperience (experience / (experience-mot + experience-car + experience-pub))

   ; calculates uncertainty as the weighted average of the deviation of own experience and neighbors' experience. Alpha and Beta correspond to Hosftede variables.
    set uncertainty  ((alpha * (1 - myexperience)) + (beta * (1 - neighborsmymode / count link-neighbors)))

  ]
end


to update-type-choice
  ask people with [satisfaction > satisfaction-threshold and uncertainty <= uncertainty-threshold] ; Hof 1 y sat thr 0
   [set type-choice "repetition" ]; repetition keeps the same transport-mode of the previous period

  ask people with [satisfaction >= satisfaction-threshold and uncertainty > uncertainty-threshold] ; AGREGAR EL IGUAL EN SATISFACTION y quitar de uncertainty Hof 0 y Sat thr 0
   [set type-choice "imitation"]
    ;set color white]

  ask people with [satisfaction <= satisfaction-threshold and uncertainty < uncertainty-threshold]  ; Hof 1 y Sat thr 1
   [set type-choice "deliberation"]
    ;set color white]

  ask people with [satisfaction < satisfaction-threshold and uncertainty >= uncertainty-threshold] ;  Hof 0 y Sat thr 1
   [set type-choice "inquiry"]
    ;set color white]
end

to choice

 ; only not committed people apply the strategy
  set commitment first (item 52 my-csv-dataset)

  ask n-of ((1 - commitment) * count (people with [type-choice = "imitation"]  ))  (people with [type-choice = "imitation"])
   [imitation]

  ask n-of ((1 - commitment) * count (people with [type-choice = "inquiry"]    ))  (people with [type-choice = "inquiry"])
   [inquiry]

  ask n-of ((1 - commitment) * count (people with [type-choice = "deliberation"])) (people with [type-choice = "deliberation"])
   [deliberation]

end

to imitation ; transpot-mode chosen according to the most used among links in their net
  let moto count link-neighbors with [t-type = 1] / count link-neighbors
  let car  count link-neighbors with [t-type = 2] / count link-neighbors
  let pub  count link-neighbors with [t-type = 3] / count link-neighbors

  if moto = max (list moto car pub) [set t-type 1 ]
  if car  = max (list moto car pub) [set t-type 2 ]
  if pub  = max (list moto car pub) [set t-type 3 ]
  if moto = car  and moto = pub  [set t-type (1 + random 3)]
  if moto = car  and moto > pub  [ifelse random-float 1 < 0.5 [set t-type 1] [set t-type 2]]
  if moto = pub  and moto > car  [ifelse random-float 1 < 0.5 [set t-type 1] [set t-type 3]]
  if car  = pub  and car  > moto [ifelse random-float 1 < 0.5 [set t-type 2] [set t-type 3]]
end

to inquiry ; Rational process that involves social interaction. Only evaluates transport modes used by contacts in the own network.

   let mot count link-neighbors with [t-type = 1]
   let car count link-neighbors with [t-type = 2]
   let pub count link-neighbors with [t-type = 3]
   set utility -1

   ; evaluates all the transport modes in the network
    if inquiry-process = "everybody"
     [
      if mot > 0 and car = 0 and pub = 0 [set utility satisfaction-mot]
      if mot = 0 and car > 0 and pub = 0 [set utility satisfaction-car]
      if mot = 0 and car = 0 and pub > 0 [set utility satisfaction-pub]
      if mot > 0 and car > 0 and pub = 0 [set utility max (list satisfaction-mot satisfaction-car)]
      if mot > 0 and car = 0 and pub > 0 [set utility max (list satisfaction-mot satisfaction-pub)]
      if mot = 0 and car > 0 and pub > 0 [set utility max (list satisfaction-car satisfaction-pub)]
      if mot > 0 and car > 0 and pub > 0 [set utility max (list satisfaction-mot satisfaction-car satisfaction-pub)]
     ]

   ; evaluates the most frequently used transport mode in the network (CREO QUE ESTE CÓDIGO FUNCIONA TAMBIÉN PARA EVALUAR "EVERYBODY")
    if inquiry-process = "most-used"
     [
      if mot = car and mot = pub [set utility one-of (list satisfaction-mot satisfaction-car satisfaction-pub) ]
      if mot = car and mot > pub [set utility one-of (list satisfaction-mot satisfaction-car)]
      if mot = pub and mot > car [set utility one-of (list satisfaction-mot satisfaction-pub)]
      if car = pub and car > mot [set utility one-of (list satisfaction-car satisfaction-pub)]
      if mot = max (list mot car pub) [set utility satisfaction-mot]
      if car = max (list mot car pub) [set utility satisfaction-car]
      if pub = max (list mot car pub) [set utility satisfaction-pub]
     ]

   ; decisión: if satisfaction with the transport mode compared is higher, then adopts that mode.   adopta sólo si halla una satisfacción mayor que la actual
    if utility > satisfaction
     [ ; compares the own utility with the highest utility among the transport modes analized)
      if utility = satisfaction-mot [set t-type 1 ]
      if utility = satisfaction-car [set t-type 2 ]
      if utility = satisfaction-pub [set t-type 3 ]
     ]
end

to deliberation ;  this is a rational and individual process of selection. The network doesn't intervene. The final selection occurs trhough a logit function.


  let beta1 w-buy
  let beta2 w-ope
  let beta3 w-saf
  let beta4 w-sec
  let beta5 w-com
  let beta6 w-tim
  let beta7 w-pol

  let utility-mot (beta1 * cost-buy-mot + beta2 * cost-op-mot + beta3 * safety-mot + beta4 * security-mot + beta5 * comfort-mot + beta6 * time-mot + beta7 * pollution-tot)

  let utility-car (beta1 * cost-buy-car + beta2 * cost-op-car + beta3 * safety-car + beta4 * security-car + beta5 * comfort-car + beta6 * time-car + beta7 * pollution-tot)

  let utility-pub (beta1 * cost-buy-pub + beta2 * cost-op-pub + beta3 * safety-pub + beta4 * security-pub + beta5 * comfort-pub + beta6 * time-pub + beta7 * pollution-tot)

  let cumulsum exp(utility-mot) + exp(utility-car) + exp(utility-pub)

  let P1 exp(utility-mot) / cumulsum

  let P2 exp(utility-car) / cumulsum

  let P3 exp(utility-pub) / cumulsum

  let choose  random-float (P1 + P2 + P3)

  ifelse choose < P1
   [set t-type 1 ]
    [ifelse choose < P1 + P2
     [set t-type 2 ]
     [set t-type 3 ]
    ]


end

to update-ownership

    ask people [
    if t-type = 1 [set moto-owner 1 set car-owner  0]
    if t-type = 2 [set car-owner  1 set moto-owner 0]
    if t-type = 3 [set car-owner  0 set moto-owner 0]
  ]

end

to update-age-people
 ask people [set age age + 1]
end

;; This is the network generating algorithm we will be using for now.
to create-social-network-fast2

  ; create variables
  let my-node one-of people
  let my-status [h-social-type] of my-node
  let my-commune [hPoly] of my-node
  let my-destination [destination-community] of my-node
  ; seeding the links for preferential attachment
  ask people with [h-social-type = 1]
  [
    create-link-with one-of other (people with [h-social-type = 1]) [set hidden? true]
  ]
  ask people with [h-social-type = 2]
  [
    create-link-with one-of other (people with [h-social-type = 2]) [set hidden? true]
  ]
  ask people with [h-social-type = 3]
  [
    create-link-with one-of other (people with [h-social-type = 3]) [set hidden? true]
  ]

  repeat (count people * 1 ) [ ; the multiplier will create an average of that many links per agent
    set my-node one-of [both-ends] of one-of links
    set my-status [h-social-type] of my-node
    set my-commune [hPoly] of my-node
    set my-destination [destination-community] of my-node
    ask my-node [
      ;; These numbers can be adjusted
      create-links-with up-to-n-of (random-exponential 15) other people with [hPoly = my-commune] [set hidden? true]
      create-links-with up-to-n-of (random-exponential 20) other people with [h-social-type = my-status] [set hidden? true]
      create-links-with up-to-n-of (random-exponential 5) other people [set hidden? true]
      ;; add 50% chance to generate these
      if random 3 = 1
      [
        create-links-with up-to-n-of (random-exponential 30) other people with [destination-community = my-destination] [set hidden? true]
      ]
    ]
  ]

end



to make-link

          ;let number-of-connections 12 ; sets how many connections we want
      ; set new node to a random end of a link; key to preferential attachment.
      ; create a link with the curated node
      let new-nodes other [both-ends] of one-of links
      create-link-with one-of new-nodes [set hidden? true]

end

to-report find-partner [number old-node]
  let link-ends []
  repeat number
  [
    let new-node [one-of both-ends] of one-of links
    ; try to find a node of same class one more time
    if [h-social-type] of new-node = [h-social-type] of old-node
    [
      set new-node [one-of both-ends] of one-of links
    ]
    ; make sure we are not linking to self or duplicates
    while [new-node = old-node or member? new-node link-ends]
    [
      set new-node [one-of both-ends] of one-of links
    ]
    set link-ends lput new-node link-ends
  ]
  let agent-ends turtle-set link-ends
  report agent-ends
end

to-report global-clustering-coefficient
  let closed-triplets sum [ nw:clustering-coefficient * count my-links * (count my-links - 1) ] of turtles
  let triplets sum [ count my-links * (count my-links - 1) ] of turtles
  report closed-triplets / triplets
end
@#$#@#$#@
GRAPHICS-WINDOW
199
10
957
769
-1
-1
5.0
1
10
1
1
1
0
0
0
1
0
149
0
149
0
0
1
ticks
30.0

BUTTON
5
10
72
43
NIL
setup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1046
30
1124
75
Male
count people with [gender = 1]
17
1
11

MONITOR
1126
30
1205
75
Female
count people with [gender = 2]
17
1
11

MONITOR
966
30
1044
75
NIL
count people
17
1
11

MONITOR
966
78
1044
123
social class 1
count people with [h-social-type = 1]
17
1
11

MONITOR
1047
78
1124
123
social class 2
count people with [h-social-type = 2]
17
1
11

MONITOR
1127
78
1204
123
social class 3
count people with [h-social-type = 3]
17
1
11

MONITOR
967
157
1048
202
NIL
count links
17
1
11

BUTTON
9
56
72
89
NIL
stop
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
10
100
74
133
go once
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

MONITOR
1774
799
1833
844
inc-tot
count people with [security = 1]
17
1
11

MONITOR
967
617
1022
662
Cars
count people with [t-type = 1]
17
1
11

MONITOR
967
670
1022
715
Moto
count people with [t-type = 2]
17
1
11

MONITOR
966
723
1023
768
Bus
count people with [t-type = 3]
17
1
11

BUTTON
9
140
72
173
go
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

INPUTBOX
12
185
73
245
deviation
0.1
1
0
Number

MONITOR
1354
576
1411
621
acc-car
acc-car-count
17
1
11

MONITOR
1412
576
1472
621
acc-mot
acc-mot-count
17
1
11

MONITOR
1472
576
1531
621
acc-pub
acc-pub-count
17
1
11

INPUTBOX
0
258
86
318
scale-population
2.0
1
0
Number

SLIDER
3
331
100
364
Uncert-m
Uncert-m
0
1
0.45
0.01
1
NIL
HORIZONTAL

SLIDER
3
368
100
401
Uncert-c
Uncert-c
0
1
0.4
0.01
1
NIL
HORIZONTAL

SLIDER
3
405
100
438
Uncert-p
Uncert-p
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
103
330
196
363
Satisf-m
Satisf-m
0
1
0.13
0.01
1
NIL
HORIZONTAL

SLIDER
102
368
196
401
Satisf-c
Satisf-c
0
1
0.09
0.01
1
NIL
HORIZONTAL

SLIDER
103
405
196
438
Satisf-p
Satisf-p
0
1
0.57
0.01
1
NIL
HORIZONTAL

CHOOSER
13
457
151
502
inquiry-process
inquiry-process
"everybody" "most-used"
0

PLOT
1032
617
1267
767
Users by mode
Periods
% of users
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"car" 1.0 0 -2674135 true "" "if (ticks mod (30)) = 2 [plot (count people with [t-type = 1 ]) / (count people)]"
"moto" 1.0 0 -16777216 true "" "if (ticks mod (30)) = 2 [plot (count people with [t-type = 2 ]) / (count people)]"
"pub" 1.0 0 -13345367 true "" "if (ticks mod (30)) = 2 [plot (count people with [t-type = 3 ]) / (count people)]"

MONITOR
1269
619
1326
664
car
count people with [t-type = 1] / count people
2
1
11

MONITOR
1269
666
1326
711
moto
count people with [t-type = 2] / count people
2
1
11

MONITOR
1269
715
1326
760
pub
count people with [t-type = 3] / count people
2
1
11

INPUTBOX
89
140
184
200
Time-steps
3.0
1
0
Number

PLOT
1295
51
1531
212
Decision type
Periods
% of users
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Rep" 1.0 0 -16777216 true "" "if (ticks mod (30) = 1) [plot count people with [type-choice = \"repetition\"]]"
"Imi" 1.0 0 -14454117 true "" "if (ticks mod (30) = 1) [plot count people with [type-choice = \"imitation\"]]"
"Del" 1.0 0 -10141563 true "" "if (ticks mod (30) = 1) [plot count people with [type-choice = \"deliberation\"]]"
"Inq" 1.0 0 -15302303 true "" "if (ticks mod (30) = 1) [plot count people with [type-choice = \"inquiry\"]]"

MONITOR
1535
36
1593
81
rep
(count people with [type-choice = \"repetition\"]) / (count people)
2
1
11

MONITOR
1536
81
1593
126
imi
(count people with [type-choice = \"imitation\"]) / (count people)
2
1
11

MONITOR
1536
126
1593
171
del
(count people with [type-choice = \"deliberation\"]) / (count people)
2
1
11

MONITOR
1536
171
1593
216
inq
(count people with [type-choice = \"inquiry\"]) / (count people)
2
1
11

PLOT
1297
220
1532
370
Satisfaction and Uncertainty
Periods
Value
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"satisf" 1.0 0 -13840069 true "" "if (ticks mod (30)) = 1 [plot mean [ satisfaction ] of people]"
"uncert" 1.0 0 -955883 true "" "if (ticks mod (30)) = 1 [plot mean [ uncertainty ] of people]"
"sat-thr" 1.0 0 -15637942 true "" "if (ticks mod (30)) = 1 [plot mean [ satisfaction-threshold ] of people]"
"unc-thr" 1.0 0 -10402772 true "" "if (ticks mod (30)) = 1 [plot mean [ uncertainty-threshold ] of people]"

TEXTBOX
967
12
1117
30
count people
14
103.0
1

TEXTBOX
968
590
1118
608
transport modes
14
103.0
1

TEXTBOX
967
135
1117
153
social network
14
103.0
1

TEXTBOX
1292
14
1442
32
decision makers
14
103.0
1

PLOT
1062
241
1262
391
density
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"density" 1.0 0 -16777216 true "" "plot mean [density] of people"

PLOT
970
401
1266
551
speed
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"average" 1.0 0 -10899396 true "" "plot mean [speed] of people"
"car" 1.0 0 -2674135 true "" "plot mean [speed] of people with [t-type = 1]"
"moto" 1.0 0 -16777216 true "" "plot mean [speed] of people with [t-type = 2]"
"pub" 1.0 0 -13345367 true "" "plot mean [speed] of people with [t-type = 3]"

MONITOR
966
241
1056
286
% in destination
(count people with [patch-here = workplace] / count people) * 100
3
1
11

TEXTBOX
970
218
1120
236
commute
14
103.0
1

MONITOR
1532
576
1589
621
tot acc
acc-car-count + acc-mot-count + acc-pub-count
17
1
11

PLOT
1354
422
1590
572
Accidents by period
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"total" 1.0 0 -10899396 true "" "if (ticks mod (30)) = 1 [plot (acc-mot-count + acc-car-count + acc-pub-count) ]"
"mot" 1.0 0 -16777216 true "" "if (ticks mod (30)) = 1 [plot acc-mot-count]"
"car" 1.0 0 -2674135 true "" "if (ticks mod (30)) = 1 [plot acc-car-count]"
"pub" 1.0 0 -13345367 true "" "if (ticks mod (30)) = 1 [plot acc-pub-count]"

PLOT
1598
421
1829
571
Accidents by tick
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"tot" 1.0 0 -10899396 true "" "plot count people with [safety = 1]"
"car" 1.0 0 -2674135 true "" "plot count people with [safety = 1 and t-type = 1]"
"mot" 1.0 0 -16777216 true "" "plot count people with [safety = 1 and t-type = 2]"
"pub" 1.0 0 -13345367 true "" "plot count people with [safety = 1 and t-type = 3]"

TEXTBOX
1355
389
1505
407
travel information
14
103.0
1

MONITOR
1598
576
1655
621
acc-car
count people with [safety = 1 and t-type = 1]
17
1
11

MONITOR
1655
576
1715
621
acc-mot
count people with [safety = 1 and t-type = 2]
17
1
11

MONITOR
1716
576
1775
621
acc-pub
count people with [safety = 1 and t-type = 3]
17
1
11

MONITOR
1774
576
1831
621
acc-tot
count people with [safety = 1]
17
1
11

PLOT
1598
632
1831
790
Incidents by tick
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -10899396 true "" "plot count people with [security = 1]"
"car" 1.0 0 -2674135 true "" "plot count people with [security = 1 and t-type = 1]"
"mot" 1.0 0 -16777216 true "" "plot count people with [security = 1 and t-type = 2]"
"pub" 1.0 0 -13345367 true "" "plot count people with [security = 1 and t-type = 3]"

PLOT
1356
632
1591
790
Incidents by period
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"tot" 1.0 0 -10899396 true "" "if (ticks mod (30)) = 1 [plot (inc-mot-count + inc-car-count + inc-pub-count) ]"
"car" 1.0 0 -2674135 true "" "if (ticks mod (30)) = 1 [plot inc-car-count]"
"mot" 1.0 0 -16777216 true "" "if (ticks mod (30)) = 1 [plot inc-mot-count]"
"pub" 1.0 0 -13345367 true "" "if (ticks mod (30)) = 1 [plot inc-pub-count]"

MONITOR
1536
225
1593
270
sat-car
mean [satisfaction] of people with [t-type = 1]
17
1
11

MONITOR
1536
272
1593
317
sat-mot
mean [satisfaction] of people with [t-type = 2]
17
1
11

MONITOR
1536
320
1593
365
sat-pub
mean [satisfaction] of people with [t-type = 3]
17
1
11

MONITOR
1597
225
1654
270
unc-car
mean [uncertainty] of people with [t-type = 1]
17
1
11

MONITOR
1597
272
1653
317
unc-mot
mean [satisfaction] of people with [t-type = 2]
17
1
11

MONITOR
1598
320
1653
365
unc-pub
mean [satisfaction] of people with [t-type = 3]
17
1
11

PLOT
1612
52
1812
202
Personal Travel Time
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"tot" 1.0 0 -10899396 true "" "if (ticks mod (30)) = 1 [plot mean [time] of people]"
"car" 1.0 0 -2674135 true "" "if (ticks mod (30)) = 1 [plot mean [time] of people with [t-type = 1]]"
"mot" 1.0 0 -16777216 true "" "if (ticks mod (30)) = 1 [plot mean [time] of people with [t-type = 2]]"
"pub" 1.0 0 -13345367 true "" "if (ticks mod (30)) = 1 [plot mean [time] of people with [t-type = 3]]"

MONITOR
1530
795
1591
840
inc-tot
inc-car-count + inc-mot-count + inc-pub-count
17
1
11

BUTTON
102
10
168
43
profile
setup                  ;; set up the model\nprofiler:start         ;; start profiling\nrepeat 32 [ go ]       ;; run something you want to measure\nprofiler:stop          ;; stop profiling\nprint profiler:report  ;; view the results\nprofiler:reset         ;; clear the data
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

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
NetLogo 6.4.0
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
0
@#$#@#$#@
