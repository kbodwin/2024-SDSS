// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): block.with(
    fill: luma(230), 
    width: 100%, 
    inset: 8pt, 
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    new_title_block +
    old_callout.body.children.at(1))
}

#show ref: it => locate(loc => {
  let target = query(it.target, loc).first()
  if it.at("supplement", default: none) == none {
    it
    return
  }

  let sup = it.supplement.text.matches(regex("^45127368-afa1-446a-820f-fc64c546b2c5%(.*)")).at(0, default: none)
  if sup != none {
    let parent_id = sup.captures.first()
    let parent_figure = query(label(parent_id), loc).first()
    let parent_location = parent_figure.location()

    let counters = numbering(
      parent_figure.at("numbering"), 
      ..parent_figure.at("counter").at(parent_location))
      
    let subcounter = numbering(
      target.at("numbering"),
      ..target.at("counter").at(target.location()))
    
    // NOTE there's a nonbreaking space in the block below
    link(target.location(), [#parent_figure.at("supplement") #counters#subcounter])
  } else {
    it
  }
})

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      block(
        inset: 1pt, 
        width: 100%, 
        block(fill: white, width: 100%, inset: 8pt, body)))
}


#let poster(
  // The poster's size.
  size: "'36x24' or '48x36''",

  // The poster's title.
  title: "Paper Title",

  // A string of author names.
  authors: "Author Names (separated by commas)",

  // Department name.
  departments: "Department Name",

  // University logo.
  univ_logo: "Logo Path",

  // Footer text.
  // For instance, Name of Conference, Date, Location.
  // or Course Name, Date, Instructor.
  footer_text: "Footer Text",

  // Any URL, like a link to the conference website.
  footer_url: "Footer URL",

  // Email IDs of the authors.
  footer_email_ids: "Email IDs (separated by commas)",

  // Color of the footer.
  footer_color: "Hex Color Code",

  // DEFAULTS
  // ========
  // For 3-column posters, these are generally good defaults.
  // Tested on 36in x 24in, 48in x 36in, and 36in x 48in posters.
  // For 2-column posters, you may need to tweak these values.
  // See ./examples/example_2_column_18_24.typ for an example.

  // Any keywords or index terms that you want to highlight at the beginning.
  keywords: (),

  // Number of columns in the poster.
  num_columns: "3",

  // University logo's scale (in %).
  univ_logo_scale: "100",

  // University logo's column size (in in).
  univ_logo_column_size: "10",

  // Title and authors' column size (in in).
  title_column_size: "20",

  // Poster title's font size (in pt).
  title_font_size: "48",

  // Authors' font size (in pt).
  authors_font_size: "36",

  // Footer's URL and email font size (in pt).
  footer_url_font_size: "30",

  // Footer's text font size (in pt).
  footer_text_font_size: "40",

  // The poster's content.
  body
) = {
  // Set the body font.
  set text(font: "STIX Two Text", size: 16pt)
  let sizes = size.split("x")
  let width = int(sizes.at(0)) * 1in
  let height = int(sizes.at(1)) * 1in
  univ_logo_scale = int(univ_logo_scale) * 1%
  title_font_size = int(title_font_size) * 1pt
  authors_font_size = int(authors_font_size) * 1pt
  num_columns = int(num_columns)
  univ_logo_column_size = int(univ_logo_column_size) * 1in
  title_column_size = int(title_column_size) * 1in
  footer_url_font_size = int(footer_url_font_size) * 1pt
  footer_text_font_size = int(footer_text_font_size) * 1pt

  // Configure the page.
  // This poster defaults to 36in x 24in.
  set page(
    width: width,
    height: height,
    margin: 
      (top: 1in, left: 2in, right: 2in, bottom: 2in),
    footer: [
      #set align(center)
      #set text(32pt)
      #block(
        fill: rgb(footer_color),
        width: 100%,
        inset: 20pt,
        radius: 10pt,
        [
          #text(font: "Courier", size: footer_url_font_size, footer_url) 
          #h(1fr) 
          #text(size: footer_text_font_size, smallcaps(footer_text)) 
          #h(1fr) 
          #text(font: "Courier", size: footer_url_font_size, footer_email_ids)
        ]
      )
    ]
  )

  // Configure equation numbering and spacing.
  set math.equation(numbering: "(1)")
  show math.equation: set block(spacing: 0.65em)

  // Configure lists.
  set enum(indent: 10pt, body-indent: 9pt)
  set list(indent: 10pt, body-indent: 9pt)

  // Configure headings.
  set heading(numbering: "I.A.1.")
  show heading: it => locate(loc => {
    // Find out the final number of the heading counter.
    let levels = counter(heading).at(loc)
    let deepest = if levels != () {
      levels.last()
    } else {
      1
    }

    set text(24pt, weight: 400)
    if it.level == 1 [
      // First-level headings are centered smallcaps.
      #set align(center)
      #set text({ 32pt })
      #show: smallcaps
      #v(50pt, weak: true)
      #if it.numbering != none {
        numbering("I.", deepest)
        h(7pt, weak: true)
      }
      #it.body
      #v(35.75pt, weak: true)
      #line(length: 100%)
    ] else if it.level == 2 [
      // Second-level headings are run-ins.
      #set text(style: "italic")
      #v(32pt, weak: true)
      #if it.numbering != none {
        numbering("i.", deepest)
        h(7pt, weak: true)
      }
      #it.body
      #v(10pt, weak: true)
    ] else [
      // Third level headings are run-ins too, but different.
      #if it.level == 3 {
        numbering("1)", deepest)
        [ ]
      }
      _#(it.body):_
    ]
  })

  // Start three column mode and configure paragraph properties.
  show: columns.with(num_columns, gutter: 64pt)
  set par(justify: true, first-line-indent: 0em)
  show par: set block(spacing: 0.65em)

  // Display the keywords.
  if keywords != () [
      #set text(24pt, weight: 400)
      #show "Keywords": smallcaps
      *Keywords* --- #keywords.join(", ")
  ]

  // Display the poster's contents.
  body
  
  // test
  
  // Arranging the logo, title, authors, and department in the header.
  align(center,
    grid(
      rows: 2,
      columns: (univ_logo_column_size, title_column_size),
      column-gutter: 0pt,
      row-gutter: 50pt,
      image(univ_logo, width: univ_logo_scale),
      text(title_font_size, title + "\n\n") + 
      text(authors_font_size, emph(authors) + 
          "   (" + departments + ") "),
    )
  )
}
// Typst custom formats typically consist of a 'typst-template.typ' (which is
// the source code for a typst template) and a 'typst-show.typ' which calls the
// template's function (forwarding Pandoc metadata values as required)
//
// This is an example 'typst-show.typ' file (based on the default template  
// that ships with Quarto). It calls the typst function named 'article' which 
// is defined in the 'typst-template.typ' file. 
//
// If you are creating or packaging a custom typst template you will likely
// want to replace this file and 'typst-template.typ' entirely. You can find
// documentation on creating typst templates here and some examples here:
//   - https://typst.app/docs/tutorial/making-a-template/
//   - https://github.com/typst/templates

#show: doc => poster(
   title: [This is an academic poster with typst and quarto!], 
  // TODO: use Quarto's normalized metadata.
   authors: [A. Smith, B. Jones, C. Brown, D. Miller], 
  
   size: "36x20", 

  // Institution logo.
  

  // Footer text.
  // For instance, Name of Conference, Date, Location.
  // or Course Name, Date, Instructor.
   footer_text: [SDSS 2024], 

  // Any URL, like a link to the conference website.
   footer_url: [the-raft.rdatatable-community.github.io], 

  // Emails of the authors.
   footer_email_ids: [r.data.table\@gmail.com], 

  // Color of the footer.
   footer_color: "ebcfb2", 

  // DEFAULTS
  // ========
  // For 3-column posters, these are generally good defaults.
  // Tested on 36in x 24in, 48in x 36in, and 36in x 48in posters.
  // For 2-column posters, you may need to tweak these values.
  // See ./examples/example_2_column_18_24.typ for an example.

  // Any keywords or index terms that you want to highlight at the beginning.
  

  // Number of columns in the poster.
  

  // University logo's scale (in %).
  

  // University logo's column size (in in).
  

  // Title and authors' column size (in in).
  

  // Poster title's font size (in pt).
  

  // Authors' font size (in pt).
  

  // Footer's URL and email font size (in pt).
  

  // Footer's text font size (in pt).
  

  doc,
)


= Lorem Ipsum Dolor
<lorem-ipsum-dolor>
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim aeque doleamus animo, cum corpore dolemus, fieri tamen permagna accessio potest, si aliquod aeternum et infinitum impendere malum nobis opinemur. Quod idem licet transferre in voluptatem, ut postea variari voluptas distinguique possit, augeri amplificarique non possit. At etiam Athenis, ut e patre audiebam facete et urbane Stoicos irridente, statua est in quo a nobis philosophia defensa et collaudata est, cum id, quod maxime placeat, facere possimus, omnis voluptas assumenda est, om- nis dolor repellendus. Temporibus autem quibusdam et.

#figure([
#box(width: 50%,image("./images/Rosetta_stone.png"))
], caption: figure.caption(
position: bottom, 
[
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim aeque doleamus animo, cum corpore dolemus, fieri tamen permagna accessio potest, si aliquod aeternum et infinitum impendere malum nobis opinemur. Quod idem licet transferre in voluptatem, ut postea variari voluptas distinguique possit, augeri amplificarique non pos- sit. At.

= Lorem ipsum
<lorem-ipsum>
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim aeque doleamus animo, cum corpore dolemus, fieri.

+ Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do.
+ Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do.
+ Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do.

Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim aeque doleamus animo, cum corpore dolemus, fieri tamen permagna accessio potest, si aliquod aeternum et infinitum impendere malum nobis opinemur. Quod idem licet transferre in voluptatem, ut.

#figure([
#figure(
align(center)[#table(
  columns: 3,
  align: (col, row) => (auto,auto,auto,).at(col),
  inset: 6pt,
  [Lorem ipsum dolor sit.], [Lorem ipsum.], [Lorem ipsum.],
  [Lorem ipsum dolor.],
  [Lorem ipsum.],
  [$alpha$],
  [Lorem ipsum.],
  [Lorem ipsum.],
  [$beta$],
  [Lorem.],
  [Lorem.],
  [$gamma$],
  [Lorem ipsum dolor.],
  [Lorem.],
  [$theta$],
)]
)

], caption: figure.caption(
position: top, 
[
Lorem ipsum dolor sit amet
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
numbering: "1", 
)
<tbl-1>


Lorem @tbl-1 ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim aeque doleamus animo, cum corpore dolemus, fieri tamen permagna accessio potest, si aliquod aeternum et infinitum impendere malum nobis opinemur. Quod idem licet transferre in voluptatem, ut postea variari voluptas distinguique possit, augeri amplificarique non possit. At etiam Athenis, ut e patre audiebam facete et urbane Stoicos irridente, statua est in quo a nobis philosophia defensa et.

== Lorem ipsum dolor sit amet
<lorem-ipsum-dolor-sit-amet>
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim aeque doleamus animo, cum corpore dolemus, fieri tamen permagna accessio potest, si aliquod aeternum et infinitum impendere malum nobis opinemur. Quod idem licet transferre in voluptatem, ut postea variari voluptas distinguique possit, augeri amplificarique non possit. At etiam Athenis, ut e patre.

#figure([
#box(width: 70%,height: 70%,image("./images/hex.png"))
], caption: figure.caption(
position: bottom, 
[
The data.table sea lion says "R! R! R!"
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


= Lorem ipsum dolor.
<lorem-ipsum-dolor.>
#block(
fill:luma(230),
inset:8pt,
radius:4pt,
[
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim aeque doleamus animo, cum corpore dolemus, fieri tamen permagna accessio potest, si aliquod aeternum et infinitum impendere malum nobis opinemur. Quod idem licet transferre in voluptatem, ut postea variari voluptas distinguique possit, augeri amplifi- carique non possit. At etiam Athenis, ut e patre audiebam facete et urbane Stoicos irridente, statua est in quo a nobis philosophia defensa et.

- Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do.
- Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do.
- Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do.

])

== Lorem ipsum etiam
<lorem-ipsum-etiam>
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim aeque doleamus animo, cum corpore dolemus, fieri tamen permagna accessio potest, si aliquod aeternum et infinitum impendere malum nobis opinemur.

== Lorem ipsum possimus
<lorem-ipsum-possimus>
Quod idem licet transferre in voluptatem, ut postea variari voluptas distinguique possit, augeri amplificarique non possit. At etiam Athenis, ut e patre audiebam facete et urbane Stoicos irridente, statua est in quo a nobis philosophia defensa et collaudata est, cum id, quod maxime placeat, facere possimus, omnis voluptas assumenda est, om- nis dolor repellendus. Temporibus autem quibusdam et.

Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim aeque doleamus animo, cum corpore dolemus, fieri tamen permagna accessio potest, si aliquod aeternum et infinitum impendere malum nobis opinemur.

#figure([
#box(width: 396.0pt, image("images/fig-airquality-1.svg"))
], caption: figure.caption(
position: bottom, 
[
Temperature and ozone level
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim aeque doleamus animo, cum corpore dolemus, fieri tamen permagna accessio potest, si aliquod aeternum et infinitum impendere malum nobis opinemur. Quod idem licet transferre in voluptatem, ut postea variari voluptas distinguique possit, augeri amplificarique non possit. At etiam Athenis, ut e patre audiebam facete et urbane Stoicos irridente, statua est in quo a nobis philosophia defensa et collaudata est, cum id, quod maxime placeat, facere possimus, omnis voluptas assumenda est, om- nis dolor repellendus. Temporibus autem quibusdam et.

- Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do.
  - Lorem ipsum dolor sit amet.
  - Lorem ipsum dolor sit amet, consectetur adipiscing elit.
- Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore.
  - Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed.
  - Lorem ipsum dolor sit amet, consectetur adipiscing.

$ sum_((k = 1))^n k = (n (n + 1)) / 2 = (n^2 + n) / 2 $
