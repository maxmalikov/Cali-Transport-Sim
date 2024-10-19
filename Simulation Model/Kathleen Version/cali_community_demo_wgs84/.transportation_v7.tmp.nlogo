extensions [gis csv nw profiler]
breed [people person] ;simulate people

;1:100 1 agent 100 people rounded

;nw:save-gexf
;nw:save-gml  "example.graphml"

;---------------Gloabl Variables------------------
globals[
  time
  my-gis-dataset         ;;gis dataset
  p-male
  p-female
 ;include in the gis dataset?
  acc-rate-mot     ; accident rate for motorcycles
  acc-rate-car     ; accident rate for cars
  acc-rate-pub     ; accident rate for public transit
  insecur-m        ; insecurity rate for motorcycles
  insecur-c        ; insecurity rate for cars
  insecur-p        ; insecurity rate for public transport
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
  age
  destination-community ;1 TO 22
  t-type          ;;1 car 2 moto 3 bus
  speed
  emission
  accident-rates
  crime-rates
  fuel-eff
  acq-score
  oper-cost
  friends
  ; INCLUDE for calulation of accidents and crimes incidents
  safety          ; 1= road accident, 0= no road accident
  security        ; 1= personal security incident, 0= no personal security incident
  safety-mot      ; safety score used for satisfaction function mot
  safety-car      ; safety score used for satisfaction function car
  safety-pub      ; safety score used for satisfaction function pub
  inc-nw-m-count; count of security incidents in network per decision period for motorcycles
  inc-nw-c-count; count of security incidents in network per decision period for car
  inc-nw-p-count; count of security incidents in network per decision period for public transit
  security-mot    ; security score used for satisfaction function mot
  security-car    ; security score used for satisfaction function car
  security-pub    ; security score used for satisfaction function pub
  acc-mot-count   ; count of accidents per decision period for motorcycles
  acc-car-count   ; count of accidents per decision period for cars
  acc-pub-count   ; count of accidents per decision period for public transit
  inc-mot-count   ; count of incidents per decision period for motorcycles
  inc-car-count   ; count of incidents per decision period for cars
  inc-pub-count   ; count of incidents per decision period for public transit
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
  set p-male 0.47
  set p-female 0.53
  ;Load Vector Boundary Data
  ;set my-gis-dataset gis:load-dataset "Data/test.shp"
  ;set my-gis-dataset gis:load-dataset "data/raw_data/shp/cali_community_wgs84.shp"
  set my-gis-dataset gis:load-dataset "cali_community_demo_wgs84.shp"

  draw ;draw the shp of cali

  ;1 setup population
  initilize-population
 ; set-gender
  set-h-social-type
  distribute-people

  set-destination ;

   ; UPDATE IN THE GIS DATASET
  set acc-rate-mot 0.40    ; accident rate for motorcycles
  set acc-rate-car 0.06    ; accident rate for cars
  set acc-rate-pub 0.05    ; accident rate for public transit
  set insecur-m    0.06    ; insecurity rate for motorcycles
  set insecur-c    0.04    ; insecurity rate for cars
  set insecur-p    0.08    ; insecurity rate for public transport





  ;create-small-world-network
  ;create-small-world-network2
  ;create-small-world-network3
  ;create-preferential-network
  ;create-social-network
  ;create-social-network-fast
  ;create-social-network-fast2
  ;nw:save-matrix "matrix-0-sn2.csv"
  ;csv:to-file "results-0-sn2.csv" [ (list who h-social-type link-neighbors [h-social-type] of link-neighbors) ] of turtles
  show "Initialization Done!"
  show timer
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
        let a item 0  m1524 / 2
        let b item 0  f1524 / 2
        let c item 0  m2459 / 2
        let d item 0  f2459 / 2
        let f item 0  m60 / 2
        let g item 0  f60 / 2

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
        ]
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
    ]
    if ctype1 = [2][
      ;show "c2"
      ask patches with [PID = y and occupied? = false and centroid? = true][
        ;show PID
        let z 1

        let a item 0  m1524 / 2
        let b item 0  f1524 / 2
        let c item 0  m2459 / 2
        let d item 0  f2459 / 2
        let f item 0  m60 / 2
        let g item 0  f60 / 2

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
          ]

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
    ]
    if ctype1 = [3][
      ;show "c3"
      ask patches with [PID = y and occupied? = false and centroid? = true][
        ;show PID
        let z 1

        let a item 0  m1524 / 2
        let b item 0  f1524 / 2
        let c item 0  m2459 / 2
        let d item 0  f2459 / 2
        let f item 0  m60 / 2
        let g item 0  f60 / 2

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
          ]

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
    ]
     set y y + 1
    ]
  ;3 set up the social network base on the type of agent

  ;
end

to set-gender
  ;;1 male 2 female
;  ask n-of (0.43 * count people) people [set gender 1]
 ; ask people with [gender != 1] [set gender 2]
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
  ; set up motor based on the real rate
  ; the rest of the people will be 40:39:21 as cars:public:cycle
  ask people [
    ;set the trasportation type then set other attrubute based on the type (motor, car, public)
    set-transportation-info-based-on-type
  ]
end

to set-transportation-info-based-on-type
  if t-type = 1[
    set speed 0
    set emission 0
    set accident-rates 0
    set crime-rates 0
    set fuel-eff 0
    set acq-score 0
    set oper-cost 0
  ]
  if t-type = 2[
    set speed 0
    set emission 0
    set accident-rates 0
    set crime-rates 0
    set fuel-eff 0
    set acq-score 0
    set oper-cost 0
  ]
  if t-type = 3[
    set speed 0
    set emission 0
    set accident-rates 0
    set crime-rates 0
    set fuel-eff 0
    set acq-score 0
    set oper-cost 0
  ]
end


;;************************;;
;;****2 Main Functions****;;
;;************************;;

;each time step the model will run the go function
to go
  ;generate random number compare wiht commuty weight to select destination community

  ;2 set up the transportation type
  ;stay the same
  ;change

  ;3 check the condition to move?
  ;3,1 update some varibales
  ;
update-safety
update-security


end


; SAFETY CALCULATION EVERY TICK


to update-safety

 ; Resets accidents every tick
  ask people [set safety 0]

 ; Resets the accident count in the system for agents for the new decision period
  ask people
   [
    if (ticks mod 30) = 1
     [set acc-mot-count 0
      set acc-car-count 0
      set acc-pub-count 0]
   ]

 ; Probability of having road accidents

  ask people with [t-type = 1]
   [ifelse ((random-float 1 <= (acc-rate-mot * 1.8 * 1.3)) and gender = 1 ) ;and  age < 35 and age > 20 )
      [set safety 1 ] ; young males are more prone to have accidents
    [ifelse (random-float 1 <= (acc-rate-mot * 1.8) and gender = 1 )
        [set safety 1]
        [if ((random-float 1 <= acc-rate-mot) and gender = 2)
          [set safety 1]
        ]
    ]
   ]

  ask people with [t-type = 2]
   [ifelse ((random-float 1 <= (acc-rate-car * 1.5)) and gender = 1 ) ;and  age < 35 and age > 20 )
        [set safety 1 ] ; young males are more prone to have accidents
    [ifelse  (random-float 1 <= acc-rate-car and gender = 1)
        [set safety 1]
        [if ((random-float 1 <= acc-rate-mot) and gender = 2)
         [set safety 1]
        ]
    ]
   ]

  ask people with [t-type = 3]
   [if random-float 1 <= acc-rate-pub [set safety 1 ]]

 ; Counts road accidents by mode in the system
  let acc-mot count people with [t-type = 1 and safety = 1]
  let acc-car count people with [t-type = 2 and safety = 1]
  let acc-pub count people with [t-type = 3 and safety = 1]

 ; Accumulates accidents during the commuting periods
  ask people
   [
    set acc-mot-count (acc-mot-count + acc-mot )
    set acc-car-count (acc-car-count + acc-car )
    set acc-pub-count (acc-pub-count + acc-pub )
   ]
end



; SECURITY CALCULATION EVRY TICK


to update-security

 ; Resets incidents every tick
  ask people [set security 0] ;Security = 0 means no incidents.

 ; Resets the incident count
  ask people
   [
    if (ticks mod 30) = 1
     [
      ; Resets the incident count in the network for the new decision period
       set inc-nw-m-count 0
       set inc-nw-c-count 0
       set inc-nw-p-count 0

      ; Resets the total incident count in the system for the new decision period
       set inc-mot-count 0
       set inc-car-count 0
       set inc-pub-count 0
     ]
   ]



 ; Probability of having personal security incidents
  ask people with [t-type = 1]
    [if random-float 1 <= insecur-m [set security 1]]

  ask people with [t-type = 2]
    [if random-float 1 <= insecur-c [set security 1]]

  ask people with [t-type = 3]
    [if random-float 1 <= insecur-p [set security 1]]

 ; Checks if people in the network have experienced insecurity incidents
  ask people
   [
    let inc-nw-m count link-neighbors with [t-type = 1 and security = 1]
    let inc-nw-c count link-neighbors with [t-type = 2 and security = 1]
    let inc-nw-p count link-neighbors with [t-type = 3 and security = 1]

    ; Accumulates incidents by mode in the network
     set inc-nw-m-count (inc-nw-m-count + inc-nw-m )
     set inc-nw-c-count (inc-nw-c-count + inc-nw-c )
     set inc-nw-p-count (inc-nw-p-count + inc-nw-p )

    ; Counts incidents in the system
     let inc-mot (count people with [security = 1 and t-type = 1] )
     let inc-car (count people with [security = 1 and t-type = 2] )
     let inc-pub (count people with [security = 1 and t-type = 3] )

    ; Accumulates incidents in the system by decision period
     set inc-mot-count (inc-mot-count + inc-mot)
     set inc-car-count (inc-car-count + inc-car)
     set inc-pub-count (inc-pub-count + inc-pub)

   ]

end

;;************************;;
;;****     3 Tools    ****;;
;;************************;;
to create-small-world-network
  ;K' code for social network
  ask people with [h-social-type = 1]
  [
    create-links-with n-of 3 other (people with [h-social-type = 1])
    let new-node one-of [ both-ends ] of one-of links
    ; Too many links when the n is large. What should the n be?
    let new-link-neighbors n-of (0.0005 * count (people with [h-social-type != 1])) (people with [h-social-type != 1])
    ask new-link-neighbors
    [
      if self != new-node
      [
        create-link-with new-node
        [set color black]
      ]
    ]
  ]

  ask people with [h-social-type = 2]
  [
    create-links-with n-of 3 other (people with [h-social-type = 2])
    let new-node one-of [ both-ends ] of one-of links
    let new-link-neighbors n-of (0.0005 * count (people with [h-social-type != 2])) (people with [h-social-type != 2])
    ask new-link-neighbors
    [
      if self != new-node
      [
        create-link-with new-node
        [set color cyan]
      ]
    ]
  ]

  ask (people with [h-social-type = 3])
  [
    create-links-with n-of 3 other (people with [h-social-type = 3])
    let new-node one-of [ both-ends ] of one-of links
    let new-link-neighbors n-of (0.0005 * count (people with [h-social-type != 3])) (people with [h-social-type != 3])
    ask new-link-neighbors
    [
      if self != new-node
      [
        create-link-with new-node
        [set hidden? hidden?]
      ]
    ]
  ]
end

to create-small-world-network2
  ;K' code for social network
  let num-soc-1 0.012 * count (people with [h-social-type != 1])
  let num-soc-2 0.012 * count (people with [h-social-type != 2])
  let num-soc-3 0.012 * count (people with [h-social-type != 3])
  ask people with [h-social-type = 1]
  [
    create-links-with n-of 5 other (people with [h-social-type = 1]) [set hidden? true]
    let new-node one-of [ both-ends ] of one-of links
    ; Too many links when the n is large. What should the n be?
    let new-link-neighbors n-of num-soc-1 (people with [h-social-type != 1])
    ask new-link-neighbors
    [
      if self != new-node
      [
        create-link-with new-node
        [set hidden? true]
      ]
    ]
  ]

  ask people with [h-social-type = 2]
  [
    create-links-with n-of 5 other (people with [h-social-type = 2]) [set hidden? true]
    let new-node one-of [ both-ends ] of one-of links
    let new-link-neighbors n-of num-soc-2 (people with [h-social-type != 2])
    ask new-link-neighbors
    [
      if self != new-node
      [
        create-link-with new-node
        [set hidden? true]
      ]
    ]
  ]

  ask (people with [h-social-type = 3])
  [
    create-links-with n-of 5 other (people with [h-social-type = 3]) [set hidden? true]
    let new-node one-of [ both-ends ] of one-of links
    let new-link-neighbors n-of num-soc-3 (people with [h-social-type != 3])
    ask new-link-neighbors
    [
      if self != new-node
      [
        create-link-with new-node
        [set hidden? true]
      ]
    ]
  ]
end

to create-small-world-network3
  ;K' code for social network
  let num-soc-1 2 * 0.011 * count (people with [h-social-type != 1])
  let num-soc-2 2 * 0.011 * count (people with [h-social-type != 2])
  let num-soc-3 2 * 0.011 * count (people with [h-social-type != 3])
  ask people with [h-social-type = 1]
  [
    create-links-with n-of 5 other (people with [h-social-type = 1]) [set hidden? true]
    let new-node one-of [ both-ends ] of one-of links
    ; Too many links when the n is large. What should the n be?
    let new-link-neighbors n-of (random num-soc-1) (people with [h-social-type != 1])
    ask new-link-neighbors
    [
      if self != new-node
      [
        create-link-with new-node
        [set hidden? true]
      ]
    ]
  ]

  ask people with [h-social-type = 2]
  [
    create-links-with n-of 5 other (people with [h-social-type = 2]) [set hidden? true]
    let new-node one-of [ both-ends ] of one-of links
    let new-link-neighbors n-of (random num-soc-2) (people with [h-social-type != 2])
    ask new-link-neighbors
    [
      if self != new-node
      [
        create-link-with new-node
        [set hidden? true]
      ]
    ]
  ]

  ask (people with [h-social-type = 3])
  [
    create-links-with n-of 5 other (people with [h-social-type = 3]) [set hidden? true]
    let new-node one-of [ both-ends ] of one-of links
    let new-link-neighbors n-of (random num-soc-3) (people with [h-social-type != 3])
    ask new-link-neighbors
    [
      if self != new-node
      [
        create-link-with new-node
        [set hidden? true]
      ]
    ]
  ]
end

to create-small-world-network4
  ;K' code for social network
  let num-soc-1 2 * 0.011 * count (people with [h-social-type != 1])
  let num-soc-2 2 * 0.011 * count (people with [h-social-type != 2])
  let num-soc-3 2 * 0.011 * count (people with [h-social-type != 3])
  ask people with [h-social-type = 1]
  [
    create-links-with n-of 5 other (people with [h-social-type = 1]) [set hidden? true]
    let new-node one-of [ both-ends ] of one-of links
    ; Too many links when the n is large. What should the n be?
    let new-link-neighbors n-of (random num-soc-1) (people with [h-social-type = 1])
    ask new-link-neighbors
    [
      if self != new-node
      [
        create-link-with new-node
        [set hidden? true]
      ]
    ]
  ]

  ask people with [h-social-type = 2]
  [
    create-links-with n-of 5 other (people with [h-social-type = 2]) [set hidden? true]
    let new-node one-of [ both-ends ] of one-of links
    let new-link-neighbors n-of (random num-soc-2) (people with [h-social-type = 2])
    ask new-link-neighbors
    [
      if self != new-node
      [
        create-link-with new-node
        [set hidden? true]
      ]
    ]
  ]

  ask (people with [h-social-type = 3])
  [
    create-links-with n-of 5 other (people with [h-social-type = 3]) [set hidden? true]
    let new-node one-of [ both-ends ] of one-of links
    let new-link-neighbors n-of (random num-soc-3) (people with [h-social-type = 3])
    ask new-link-neighbors
    [
      if self != new-node
      [
        create-link-with new-node
        [set hidden? true]
      ]
    ]
  ]
end

to create-preferential-network
  ; seeding the links for preferential attachment
  ask n-of 20 people with [h-social-type = 1]
  [
    create-link-with one-of other (people with [h-social-type = 1]) [set hidden? true]
  ]
  ask n-of 20 people with [h-social-type = 2]
  [
    create-link-with one-of other (people with [h-social-type = 2]) [set hidden? true]
  ]
  ask n-of 20 people with [h-social-type = 3]
  [
    create-link-with one-of other (people with [h-social-type = 3]) [set hidden? true]
  ]
  ask people
  [
    ;let number-of-connections 12 ; sets how many connections we want
    ; set new node to a random end of a link; key to preferential attachment.
    let new-nodes find-partner 12 self
    ; create a link with the curated node
    create-links-with new-nodes [set hidden? true]
  ]

end

to create-social-network
  ; seeding the links for preferential attachment
  ask people with [h-social-type = 1]
  [
    create-links-with n-of 5 other (people with [h-social-type = 1]) [set hidden? true]
  ]
  ask people with [h-social-type = 2]
  [
    create-links-with n-of 5 other (people with [h-social-type = 2]) [set hidden? true]
  ]
  ask people with [h-social-type = 3]
  [
    create-links-with n-of 5 other (people with [h-social-type = 3]) [set hidden? true]
  ]
  repeat (count people * 10 ) [ ; the multiplier will create an average of that many links per agent
    ask one-of people
    [
      make-link
    ]
  ]
end


to create-social-network-fast
  ; seeding the links for preferential attachment
  ask people with [h-social-type = 1]
  [
    create-links-with n-of 5 other (people with [h-social-type = 1]) [set hidden? true]
  ]
  ask people with [h-social-type = 2]
  [
    create-links-with n-of 5 other (people with [h-social-type = 2]) [set hidden? true]
  ]
  ask people with [h-social-type = 3]
  [
    create-links-with n-of 5 other (people with [h-social-type = 3]) [set hidden? true]
  ]
  let clustering-coef 10
  repeat (count people * clustering-coef)
  [
    ask one-of links
    [
      let linker self
      if ([h-social-type] of one-of [both-ends] of linker) = 1
      [
        ask one-of people with [h-social-type = 1]
        [
          if all? [both-ends] of linker [ self != myself]
          [
          create-links-with [both-ends] of linker [set hidden? true]
          ]
        ]
      ]
      if ([h-social-type] of one-of [both-ends] of linker) = 2
      [
        ask one-of people with [h-social-type = 2]
        [
          if all? [both-ends] of linker [ self != myself]
          [
          create-links-with [both-ends] of linker [set hidden? true]
          ]
        ]
      ]
      if ([h-social-type] of one-of [both-ends] of linker) = 3
      [
        ask one-of people with [h-social-type = 3]
        [
          if all? [both-ends] of linker [ self != myself]
          [
          create-links-with [both-ends] of linker [set hidden? true]
          ]
        ]
      ]
    ]
  ]
    repeat (count people * 1.5 ) [ ; the multiplier will create an average of that many links per agent
    ask one-of [both-ends] of one-of links
    [
      create-links-with n-of (random 100) other people [set hidden? true ]
      ;create-link-with one-of other people [set hidden? true ]
    ]
  ]
end

to create-social-network-fast2

  ; create variables
  let my-node one-of people
  let my-status [h-social-type] of my-node
  let my-commune [hPoly] of my-node
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
    ask my-node [
      create-links-with up-to-n-of (random-exponential 5) other people with [hPoly = my-commune] [set hidden? true]
      create-links-with up-to-n-of (random-exponential 10) other people with [h-social-type = my-status] [set hidden? true]
      create-links-with up-to-n-of (random-exponential 65) other people [set hidden? true]
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
210
10
968
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
1
1
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
78
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
974
56
1178
101
Male
count people with [gender = 1]
17
1
11

MONITOR
974
102
1178
147
Female
count people with [gender = 2]
17
1
11

MONITOR
974
10
1068
55
NIL
count people
17
1
11

MONITOR
974
154
1218
199
NIL
count people with [h-social-type = 1]
17
1
11

MONITOR
974
207
1218
252
NIL
count people with [h-social-type = 2]
17
1
11

MONITOR
974
259
1218
304
NIL
count people with [h-social-type = 3]
17
1
11

MONITOR
974
307
1055
352
NIL
count links
17
1
11

MONITOR
973
364
1278
409
NIL
count people with [destination-community = 1]
17
1
11

MONITOR
977
417
1282
462
NIL
count people with [destination-community = 2]
17
1
11

MONITOR
980
471
1285
516
NIL
count people with [destination-community = 3]
17
1
11

MONITOR
981
520
1294
565
NIL
count people with [destination-community = 22]
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

MONITOR
982
571
1147
616
NIL
global-clustering-coefficient
17
1
11

BUTTON
10
100
73
133
NIL
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
984
626
1049
671
accidents
count people with [safety = 1]
17
1
11

MONITOR
1057
626
1119
671
incidents
count people with [security = 1]
17
1
11

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
