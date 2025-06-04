#columns(2, [
    #image("media/logo_heig-vd-2020.svg", width: 40%)
    #colbreak()
    #par(justify: false)[
        #align(right, [
            Department of Information and Communication Technologies (ICT)
        ])
    ] 
    #v(1%)
    #par(justify:false)[
        #align(right, [
            Computer Science and Communication Systems
        ])
    ]
    #v(1%)
    #par(justify:false)[
        #align(right, [
            High Performance Coding
        ])
    ]
  ])
  
#v(20%)

#align(center, [#text(size: 14pt, [*HPC*])])
#v(4%)
#align(center, [#text(size: 20pt, [*Open Source Optimization*])])
#v(1%)
#align(center, [#text(size: 16pt, [*LVGL - Tinyttf*])])

#v(8%)

#align(left, [#block(width: 70%, [
    #table(
      stroke: none,
      columns: (25%, 75%),
      [*Student*], [André Costa & Alexandre Iorio],
      [*Teacher*], [Alberto Dassatti],
      [*Assistant*], [Bruno Da Rocha Carvalho],
      [*Year*], [2025]
    )
  ])])

#align(bottom + right, [
    Yverdon-les-Bains, #datetime.today().display("[day].[month].[year]")
  ])
