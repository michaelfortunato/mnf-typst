#import "@preview/lemmify:0.1.8": *
#import "@preview/cetz:0.3.4": canvas, draw, tree
#import "@preview/subpar:0.2.1"


// Workaround for the lack of an `std` scope.
#let std-bibliography = bibliography

// Metrical size of page body.
#let viewport = (
  width: 5.5in,
  height: 9in,
)

// Default font sizes from original LaTeX style file.
#let font-defaults = (
  tiny: 7pt,
  scriptsize: 7pt,
  footnotesize: 9pt,
  small: 9pt,
  normalsize: 10pt,
  large: 14pt,
  Large: 16pt,
  LARGE: 20pt,
  huge: 23pt,
  Huge: 28pt,
)

// We prefer to use Times New Roman when ever it is possible.
#let font-family = ("Times New Roman",)
// Some alternatives are ("Nimbus Roman", "TeX Gyre Termes")

#let font = (
  Large: font-defaults.Large,
  footnote: font-defaults.footnotesize,
  large: font-defaults.large,
  small: font-defaults.small,
  normal: font-defaults.normalsize,
  script: font-defaults.scriptsize,
)

#let anonymous-author = (
  name: "Anonymous Author(s)",
  email: "anon.email@example.org",
  affl: ("anonymous-affl",),
)

#let anonymous-affl = (
  department: none,
  institution: "Affilation",
  location: "Address",
)

#let anonymous-notice = [
  Submitted to 37th Conference on Neural Information Processing Systems
  (NeurIPS 2023). Do not distribute.
]

#let arxiv-notice = [Preprint. Under review.]

#let public-notice = [
  37th Conference on Neural Information Processing Systems (NeurIPS 2023).
]

#let get-notice(accepted) = if accepted == none {
  return arxiv-notice
} else if accepted {
  return public-notice
} else {
  return anonymous-notice
}

#let format-author-names(authors) = {
  // Formats the author's names in a list with commas and a
  // final "and".
  let author_names = authors.map(author => author.name)
  let author-string = if authors.len() == 2 {
    author_names.join(" and ")
  } else {
    author_names.join(", ", last: ", and ")
  }
  return author_names
}

#let format-author-name(author, affl2idx, affilated: false) = {
  // Sanitize author affilations.
  let affl = author.at("affl")
  if type(affl) == str {
    affl = (affl,)
  }
  let indices = affl.map(it => str(affl2idx.at(it))).join(" ")
  let result = strong(author.name)
  if affilated {
    result += super(typographic: false, indices)
  }
  return box(result)
}

#let format-afflilation(affl) = {
  assert(affl.len() > 0, message: "Affilation must be non-empty.")

  // Concatenate terms which representat affilation to a single text.
  let affilation = ""
  if type(affl) == array {
    affilation = affl.join(", ")
  } else if type(affl) == dictionary {
    let terms = ()
    if "department" in affl and affl.department != none {
      terms.push(affl.department)
    }
    if "institution" in affl and affl.institution != none {
      terms.push(affl.institution)
    }
    if "location" in affl and affl.location != none {
      terms.push(affl.location)
    }
    if "country" in affl and affl.country != none {
      terms.push(affl.country)
    }
    affilation = terms.filter(it => it.len() > 0).join(", ")
  } else {
    assert(false, message: "Unexpected execution branch.")
  }

  return affilation
}

#let make-single-author(author, affls, affl2idx) = {
  // Sanitize author affilations.
  let affl = author.at("affl")
  if type(affl) == str {
    affl = (affl,)
  }

  // Render author name.
  let name = format-author-name(author, affl2idx)
  // Render affilations.
  let affilation = affl
    .map(it => format-afflilation(affls.at(it)))
    .map(it => box(it))
    .join(" ")

  let lines = (name, affilation)
  if "email" in author {
    let uri = "mailto:" + author.email
    let text = raw(author.email)
    lines.push(box(link(uri, text)))
  }

  // Combine all parts of author's info.
  let body = lines.join([\ ])
  return align(center, body)
}

#let make-two-authors(authors, affls, affl2idx) = {
  let row = authors
    .map(it => make-single-author(it, affls, affl2idx))
    .map(it => box(it))
  return align(center, grid(columns: (1fr, 1fr), gutter: 2em, ..row))
}

#let make-many-authors(authors, affls, affl2idx) = {
  let format-affl(affls, key, index) = {
    let affl = affls.at(key)
    let affilation = format-afflilation(affl)
    let entry = super(typographic: false, [#index]) + affilation
    return box(entry)
  }

  // Concatenate all author names with affilation superscripts.
  let names = authors.map(it => format-author-name(
    it,
    affl2idx,
    affilated: true,
  ))

  // Concatenate all affilations with superscripts.
  let affilations = affl2idx.pairs().map(it => format-affl(affls, ..it))

  // Concatenate all emails to a single paragraph.
  let emails = authors
    .filter(it => "email" in it)
    .map(it => box(link("mailto:" + it.email, raw(it.email))))

  // Combine paragraph pieces to single array, then filter and join to
  // paragraphs.
  let paragraphs = (names, affilations, emails)
    .filter(it => it.len() > 0)
    .map(it => it.join(h(1em, weak: true)))
    .join([#parbreak() ])

  return align(center, {
    pad(left: 1em, right: 1em, paragraphs)
  })
}

#let make-authors(authors, affls) = {
  // Prepare authors and footnote anchors.
  let ordered-affls = authors.map(it => it.affl).flatten().dedup()
  let affl2idx = ordered-affls
    .enumerate(start: 1)
    .fold((:), (acc, it) => {
      let (ix, affl) = it
      acc.insert(affl, ix)
      return acc
    })

  if authors.len() == 1 {
    return make-single-author(authors.at(0), affls, affl2idx)
  } else if authors.len() == 2 {
    return make-two-authors(authors, affls, affl2idx)
  } else {
    return make-many-authors(authors, affls, affl2idx)
  }
}

//// ****** MNF START
//
// Patch neurips bloated to get it all right
#let make_figure_caption(it) = {
  set align(center)
  block({
    set align(left)
    set text(size: font.normal)
    it.supplement
    if it.numbering != none {
      [ ]
      context it.counter.display(it.numbering)
    }
    it.separator
    [ ]
    it.body
  })
}
#let make_figure(caption_above: false, it) = {
  let body = block(width: 100%, {
    set align(center)
    set text(size: font.normal)
    if caption_above {
      v(1em, weak: true) // Does not work at the block beginning.
      it.caption
    }
    v(1em, weak: true)
    it.body
    v(8pt, weak: true) // Original 1em.
    if not caption_above {
      it.caption
      v(1em, weak: true) // Does not work at the block ending.
    }
  })

  if it.placement == none {
    return body
  } else {
    return place(it.placement, body, float: true, clearance: 2.3em)
  }
}
#let scr(it) = text(features: ("ss01",), box($cal(it)$))




#let affls = (
  uChicago: ("University of Chicago", "Chicago", "USA"),
)

#let authors = (
  (
    name: "Michael Newman Fortunato",
    affl: "uChicago",
    email: "michaelfortunato@uchicago.edu",
    equal: true,
  ),
)

#let (
  theorem,
  lemma,
  corollary,
  remark,
  proposition,
  definition,
  example,
  proof,
  rules: theorem_rules,
) = default-theorems("theorem_group", lang: "en")

//// ****** MNF END

/**
 * neurips2023
 *
 * Args:
 *   accepted: Valid values are `none`, `false`, and `true`. Missing value
 *   (`none`) is designed to prepare arxiv publication. Default is `false`.
 */
#let neurips2023(
  title: [],
  authors: (),
  keywords: (),
  date: auto,
  abstract: none,
  bibliography: none,
  bibliography-opts: (:),
  accepted: false,
  aux: (:),
  body,
) = {
  // Sanitize authors and affilations arguments.
  if accepted != none and not accepted {
    authors = ((anonymous-author,), (anonymous-affl: anonymous-affl))
  }
  let (authors, affls) = authors

  // Configure document metadata.
  set document(
    title: title,
    author: format-author-names(authors),
    keywords: keywords,
    date: date,
  )

  set page(
    paper: "us-letter",
    margin: (left: 1.5in, right: 1.5in, top: 1.0in, bottom: 1in),
    footer-descent: 25pt - font.normal,
  )

  // In the original style, main body font is Times (Type-1) font but we use
  // OpenType analogue.
  set par(justify: true, leading: 0.55em)
  set text(font: font-family, size: font.normal)

  // Configure quotation (similar to LaTeX's `quoting` package).
  show quote: set align(left)
  show quote: set pad(x: 4em)
  show quote: set block(spacing: 1em) // Original 11pt.

  // Configure spacing code snippets as in the original LaTeX.
  show raw.where(block: true): set block(spacing: 14pt) // TODO: May be 15pt?

  // Configure bullet lists.
  show list: set block(spacing: 15pt) // Original unknown.
  set list(
    indent: 30pt, // Original 3pc (=36pt) without bullet.
    spacing: 8.5pt,
  )

  // Configure footnote.
  set footnote.entry(
    separator: line(length: 2in, stroke: 0.5pt),
    clearance: 6.65pt,
    indent: 12pt,
  ) // Original 11pt.

  // Configure heading appearence and numbering.
  set heading(numbering: "1.1")
  show heading: it => {
    // Create the heading numbering.
    let number = if it.numbering != none {
      counter(heading).display(it.numbering)
    }

    set align(left)
    if it.level == 1 {
      // TODO: font.large?
      text(size: 12pt, weight: "bold", {
        let ex = 7.95pt
        v(2.7 * ex, weak: true)
        [#number *#it.body*]
        v(2 * ex, weak: true)
      })
    } else if it.level == 2 {
      text(size: font.normal, weight: "bold", {
        let ex = 6.62pt
        v(2.70 * ex, weak: true)
        [#number *#it.body*]
        v(2.03 * ex, weak: true) // Original 1ex.
      })
    } else if it.level == 3 {
      text(size: font.normal, weight: "bold", {
        let ex = 6.62pt
        v(2.6 * ex, weak: true)
        [#number *#it.body*]
        v(1.8 * ex, weak: true) // Original -1em.
      })
    }
  }

  // Configure images and tables appearence.
  set figure.caption(separator: [:])
  show figure: set block(breakable: false)
  show figure.caption.where(kind: table): it => make_figure_caption(it)
  show figure.caption.where(kind: image): it => make_figure_caption(it)
  show figure.where(kind: image): it => make_figure(it)
  show figure.where(kind: table): it => make_figure(it, caption_above: true)

  // Math equation numbering and referencing.
  set math.equation(numbering: "(1)")
  show ref: it => {
    let eq = math.equation
    let el = it.element
    if el != none and el.func() == eq {
      let numb = numbering("1", ..counter(eq).at(el.location()))
      let color = rgb(0%, 8%, 45%) // Originally `mydarkblue`. :D
      let content = link(el.location(), text(fill: color, numb))
      [(#content)]
    } else {
      return it
    }
  }

  // Configure algorithm rendering.
  counter(figure.where(kind: "algorithm")).update(0)
  show figure.caption.where(kind: "algorithm"): it => {
    strong[#it.supplement #it.counter.display(it.numbering)]
    [ ]
    it.body
  }
  show figure.where(kind: "algorithm"): it => {
    place(top, float: true, block(breakable: false, width: 100%, {
      set block(spacing: 0em)
      line(length: 100%, stroke: (thickness: 0.08em))
      block(spacing: 0.4em, it.caption) // NOTE: No idea why we need it.
      line(length: 100%, stroke: (thickness: 0.05em))
      it.body
      line(length: 100%, stroke: (thickness: 0.08em))
    }))
  }

  // Render title.
  block(width: 5.5in, {
    // We need to define line widths to reuse them in spacing.
    let top-rule-width = 4pt
    let bot-rule-width = 1pt

    // Add some space based on line width.
    v(0.1in + top-rule-width / 2)
    line(length: 100%, stroke: top-rule-width + black)
    align(center, text(size: 17pt, weight: "bold", [#title]))
    v(-bot-rule-width)
    line(length: 100%, stroke: bot-rule-width + black)
  })

  v(0.25in)

  // Render authors.
  block(width: 100%, {
    set text(size: font.normal)
    set par(leading: 4.5pt)
    set par(spacing: 1.0em) // Original 11pt.
    make-authors(authors, affls)
    v(0.3in - 0.1in)
  })

  // Vertical spacing between authors and abstract.
  v(6.5pt) // Original 0.075in.

  // Render abstract.
  block(width: 100%, {
    set text(size: 10pt)
    set text(size: font.normal)
    set par(leading: 0.43em) // Original 0.55em (or 0.45em?).

    // NeurIPS instruction tels that font size of `Abstract` must equal to 12pt
    // but there is not predefined font size.
    align(center, text(size: 12pt)[*Abstract*])
    v(0.215em) // Original 0.5ex.
    pad(left: 0.5in, right: 0.5in, abstract)
    v(0.43em) // Original 0.5ex.
  })

  v(0.43em / 2) // No idea.

  // Render main body
  {
    // Display body.
    set text(size: font.normal)
    set par(leading: 0.55em)
    set par(leading: 0.43em)
    set par(spacing: 1.0em) // Original 11pt.
    body

    // Display the bibliography, if any is given.
    if bibliography != none {
      if "title" not in bibliography-opts {
        bibliography-opts.title = "References"
      }
      if "style" not in bibliography-opts {
        bibliography-opts.style = "ieee"
      }
      // NOTE It is allowed to reduce font to 9pt (small) but there is not
      // small font of size 9pt in original sty.
      show std-bibliography: set text(size: font.small)
      set std-bibliography(..bibliography-opts)
      bibliography
    }
  }
}

/**
 * A routine for setting paragraph heading.
 */
#let paragraph(body) = {
  parbreak()
  [*#body*]
  h(1em, weak: true)
}

/**
 * A routine for rendering external links in monospace font.
 */
#let url(uri) = {
  return link(uri, raw(uri))
}

/**
 * neurips2024.typ
 *
 * Template for The 38-th Annual Conference on Neural Information Processing
 * Systems (NeurIPS) 2024.
 *
 * [1]: https://neurips.cc/Conferences/2024
 */

// Workaround for the lack of an `std` scope.
#let std-bibliography = bibliography

// Tickness values are taken from booktabs.
#let botrule = table.hline(stroke: (thickness: 0.08em))
#let midrule = table.hline(stroke: (thickness: 0.05em))
#let toprule = botrule

#let anonymous-notice = [
  Submitted to 38th Conference on Neural Information Processing Systems
  (NeurIPS 2024). Do not distribute.
]

#let arxiv-notice = [Preprint. Under review.]

#let public-notice = [
  38th Conference on Neural Information Processing Systems (NeurIPS 2024).
]

#let get-notice(accepted) = if accepted == none {
  return arxiv-notice
} else if accepted {
  return public-notice
} else {
  return anonymous-notice
}

/**
 * neurips2024
 *
 * Args:
 *   accepted: Valid values are `none`, `false`, and `true`. Missing value
 *   (`none`) is designed to prepare arxiv publication. Default is `false`.
 */
#let neurips2024(
  title: [],
  authors: (),
  keywords: (),
  date: auto,
  abstract: none,
  bibliography: none,
  bibliography-opts: (:),
  appendix: none,
  accepted: false,
  body,
) = {
  show: neurips2023.with(
    title: title,
    authors: authors,
    keywords: keywords,
    date: date,
    abstract: abstract,
    accepted: accepted,
    aux: (get-notice: get-notice),
  )
  body
  // Display the bibliography, if any is given.
  if bibliography != none {
    if "title" not in bibliography-opts {
      bibliography-opts.title = "References"
    }
    if "style" not in bibliography-opts {
      bibliography-opts.style = "ieee"
    }
    // NOTE It is allowed to reduce font to 9pt (small) but there is not
    // small font of size 9pt in original sty.
    show std-bibliography: set text(size: font.small)
    set std-bibliography(..bibliography-opts)
    bibliography
  }

  if appendix != none {
    set heading(numbering: "A.1")
    counter(heading).update(0)
    appendix
  }
}




// Default edge draw callback
//
// - from (string): Source element name
// - to (string): Target element name
// - parent (node): Parent (source) tree node
// - child (node): Child (target) tree node
#let default-draw-edge(from, to, parent, child) = {
  draw.line(from, to)
}

// Default node draw callback
//
// - node (node): The node to draw
#let default-draw-node(node, _) = {
  let text = if type(node) in (content, str, int, float) {
    [#node]
  } else if type(node) == dictionary {
    node.content
  }

  draw.get-ctx(ctx => {
    draw.content((), text)
  })
}

// Function to draw a star graph with n outer nodes
#let draw-star-graph(
  n,
  node_label_fn: i => text(str(i)),
  node_color_function: i => white,
) = {
  canvas({
    import draw: *

    let radius = 1 // Radius of the circle for outer nodes
    let center = (0, 0) // Position of the central node

    // Calculate positions of outer nodes
    let nodes = (center,)
    for i in range(n) {
      let angle = 360deg / n * i
      let x = radius * calc.cos(angle)
      let y = radius * calc.sin(angle)
      nodes.push((x, y))
    }

    // Draw edges from center to all outer nodes
    for i in range(1, n + 1) {
      line(nodes.at(0), nodes.at(i), stroke: 1pt)
    }

    // Draw all nodes
    for (i, pos) in nodes.enumerate() {
      circle(pos, radius: 0.3, fill: node_color_function(i), stroke: 1pt)
      content(pos, node_label_fn(i), anchor: "center")
    }
  })
}

#let draw-graph-from-adj-matrix2(
  adj-matrix,
  positions: none,
  layout: "circular", // New parameter: "circular" or "bipartite"
  node_label_fn: i => text(str(i + 1)),
  node_color_function: i => white,
  node-radius: 0.45,
  stroke: (thickness: 1pt),
) = {
  canvas({
    import draw: *

    // Number of nodes (assuming the matrix is square)
    let n = adj-matrix.len()
    if n == 0 or adj-matrix.at(0).len() != n {
      panic("Adjacency matrix must be square")
    }
    let stroke = 1pt

    // Helper function to check if the graph is bipartite and partition vertices
    let is-bipartite(adj-matrix) = {
      let n = adj-matrix.len()
      let colors = array
        .range(n)
        .map(_ => none) // none: uncolored, 0 or 1: bipartite sets
      let queue = (0,) // Start BFS from vertex 0
      colors.at(0) = 0 // Assign vertex 0 to set 0

      // BFS to color vertices
      while queue.len() > 0 {
        let u = queue.at(0)
        queue = queue.slice(1) // Remove u from queue
        for v in range(n) {
          if adj-matrix.at(u).at(v) == 1 {
            // Edge between u and v
            if colors.at(v) == none {
              // Uncolored vertex
              colors.at(v) = if colors.at(u) == 0 { 1 } else { 0 }
              queue.push(v)
            } else if colors.at(v) == colors.at(u) {
              // Conflict: same color
              return (false, none, none)
            }
          }
        }
      }

      // Partition vertices into two sets based on colors
      let set0 = ()
      let set1 = ()
      for i in range(n) {
        if colors.at(i) == 0 {
          set0.push(i)
        } else if colors.at(i) == 1 {
          set1.push(i)
        }
      }
      (true, set0, set1)
    }

    // Determine node positions
    let node-positions = if positions != none {
      // Use provided positions
      if positions.len() != n {
        panic("Number of positions must match number of nodes")
      }
      positions
    } else if layout == "bipartite" {
      // Bipartite layout: two columns
      let (is-bip, set0, set1) = is-bipartite(adj-matrix)
      if not is-bip {
        // Fallback to circular if not bipartite
        let radius = calc.max(2, calc.sqrt(n)) / 2
        let center = (0, 0)
        let positions = ()
        for i in range(n) {
          let angle = 360deg / n * i
          let x = radius * calc.cos(angle)
          let y = radius * calc.sin(angle)
          positions.push((x, y))
        }
        positions
      } else {
        // Place vertices in two columns
        let positions = array.range(n).map(_ => (0, 0))
        let max-set-size = calc.max(set0.len(), set1.len())
        let height = calc.max(2, max-set-size) // Vertical spacing
        let width = 2 // Horizontal separation between sets

        // Position set0 on the left (x = -1)
        let y-step0 = if set0.len() > 1 { height / (set0.len() - 1) } else {
          0
        }
        for (i, v) in set0.enumerate() {
          let y = -height / 2 + i * y-step0
          positions.at(v) = (-width / 2, y)
        }

        // Position set1 on the right (x = 1)
        let y-step1 = if set1.len() > 1 { height / (set1.len() - 1) } else {
          0
        }
        for (i, v) in set1.enumerate() {
          let y = -height / 2 + i * y-step1
          positions.at(v) = (width / 2, y)
        }

        positions
      }
    } else {
      // Default: Circular layout
      let radius = calc.max(2, calc.sqrt(n)) / 2
      let center = (0, 0)
      let positions = ()
      for i in range(n) {
        let angle = 360deg / n * i
        let x = radius * calc.cos(angle)
        let y = radius * calc.sin(angle)
        positions.push((x, y))
      }
      positions
    }

    // Draw edges based on the adjacency matrix
    for i in range(n) {
      for j in range(i + 1, n) {
        if adj-matrix.at(i).at(j) == 1 {
          line(node-positions.at(i), node-positions.at(j), stroke: stroke)
        }
      }
    }

    // Draw nodes
    for (i, pos) in node-positions.enumerate() {
      circle(
        pos,
        radius: node-radius,
        fill: node_color_function(i),
        stroke: stroke,
      )
      content(pos, node_label_fn(i), anchor: "center")
    }
  })
}


// Function to draw a graph from an adjacency matrix
#let draw-graph-from-adj-matrix(
  adj-matrix,
  positions: none,
  node_label_fn: i => text(str(i + 1)),
  node_color_function: i => white,
  layout: "circular", // New parameter: "circular" or "bipartite"
  node-radius: 0.45,
  // edge_label_function (i, j) => content(i,j, [edge #i #j], anchor: "center")
  edge_label_function: (i_idx, i_pos, j_idx, j_pos) => none,
  stroke: (thickness: 1pt), // Changed to dictionary format
  radius: none,
) = {
  canvas({
    import draw: *

    // Number of nodes (assuming the matrix is square)
    let n = adj-matrix.len()
    if n == 0 or adj-matrix.at(0).len() != n {
      panic("Adjacency matrix must be square")
    }

    // Determine node positions
    let node-positions = if positions == none {
      // Default: Circular layout
      let radius = if radius == none {
        (
          calc.max(2, calc.sqrt(n)) / 2
        )
      } else {
        (radius)
      } // Adjust radius based on number of nodes
      let center = (0, 0)
      let positions = ()
      for i in range(n) {
        let angle = 360deg / n * i
        let x = radius * calc.cos(angle)
        let y = radius * calc.sin(angle)
        positions.push((x, y))
      }
      positions
    } else {
      // Use provided positions
      if positions.len() != n {
        panic("Number of positions must match number of nodes")
      }
      positions
    }

    // Draw edges based on the adjacency matrix
    for i in range(n) {
      for j in range(i + 1, n) {
        // Only upper triangle for undirected graph
        if adj-matrix.at(i).at(j) == 1 {
          line(node-positions.at(i), node-positions.at(j), stroke: 1pt)
          edge_label_function(i, node-positions.at(i), j, node-positions.at(j))
        }
      }
    }

    // Draw nodes
    for (i, pos) in node-positions.enumerate() {
      circle(
        pos,
        radius: node-radius,
        fill: node_color_function(i),
        stroke: 1pt,
      )
      content(pos, node_label_fn(i), anchor: "center")
    }
  })
}

/// An experimental thing
/// Supposed to be EXACTLY like the latex one
/// rubber-article doesn't do it.
/// ams-article doesn't do it.
/// I have to do it.
/// but the left margin is too far in and
/// the section numbering is too near to the section title
#let mnf_hw(title: str, doc) = {
  let title-page(title: "", author: "", date: none) = {
    set align(center)
    set block(spacing: 2em) // Space before title
    v(9.3em) // Space between title and author

    text(size: 16pt, weight: "thin")[#title]
    v(1.2em) // Space between title and author

    text(size: 12pt)[#author]
    v(.9em) // Space between author and date

    text(size: 12pt)[#date]
    v(1.2em) // Space after date before content
  }


  set text(size: 10pt, font: "New Computer Modern", lang: "en")
  show raw: set text(size: 10pt, font: "New Computer Modern Mono")
  // First, adjust your left margin to match LaTeX's actual calculation
  set page(paper: "us-letter", margin: (
    left: 47.25mm, // This is the exact LaTeX margin from the log
    right: 47.5mm, // Balanced margin
    top: 25.4mm,
    bottom: 38.1mm,
  ))
  // show heading.where(level: 1): set block(above: 1.4em, below: 1.15em)
  show heading: set block(above: 1.5em, below: 1.1em)
  // Then, update your heading style to match LaTeX's section indentation
  set heading(numbering: (..numbers) => {
    let number = numbers.pos().map(str).join(".")
    // No additional indentation before the number since we've set the correct margin
    [#number #h(0.8em)] // Just add the spacing between number and content
  })
  set par(
    leading: 0.55em,
    spacing: 0.55em,
    first-line-indent: 1.5em,
    justify: true,
  )
  title-page(
    title: title,
    date: datetime.today().display("[month repr:long] [day], [year]"),
    author: "Michael Newman Fortunato",
  )
  set math.equation(numbering: "(1)")
  doc
}

// An attempt to get as close as possible to ams latex article class
// I used in college and gradschool
#let mnf_ams_article(
  title: [],
  authors: (authors, affls),
  keywords: (),
  date: auto,
  bibliography: none,
  bibliography-opts: (:),
  appendix: none,
  // Number for the section
  section_numbering: "1.1",
  doc,
) = {
  let (authors, affls) = if authors.len() > 0 { authors } else { ((), ()) }

  // Configure document metadata.
  set document(
    title: title,
    author: format-author-names(authors),
    keywords: keywords,
    date: date,
  )

  set page(
    paper: "us-letter",
    margin: (left: 1.5in, right: 1.5in, top: 1.0in, bottom: 1in),
    footer-descent: 25pt - font.normal,
  )

  // In the original style, main body font is Times (Type-1) font but we use
  // OpenType analogue.
  set par(justify: true, leading: 0.55em)
  set text(font: font-family, size: font.normal)

  // Configure quotation (similar to LaTeX's `quoting` package).
  show quote: set align(left)
  show quote: set pad(x: 4em)
  show quote: set block(spacing: 1em) // Original 11pt.

  // Configure spacing code snippets as in the original LaTeX.
  show raw.where(block: true): set block(spacing: 14pt) // TODO: May be 15pt?

  // Configure bullet lists.
  show list: set block(spacing: 15pt) // Original unknown.
  set list(
    indent: 30pt, // Original 3pc (=36pt) without bullet.
    spacing: 8.5pt,
  )

  // Configure footnote.
  set footnote.entry(
    separator: line(length: 2in, stroke: 0.5pt),
    clearance: 6.65pt,
    indent: 12pt,
  ) // Original 11pt.

  // Configure heading appearence and numbering.
  set heading(numbering: section_numbering)
  show heading: it => {
    // Create the heading numbering.
    let number = if it.numbering != none {
      // NOTE: Why display here? Could we not just get the formatted number
      // TODO: Does this actually display?
      counter(heading).display(it.numbering)
    } else {
      none
    }

    set align(left)
    if it.level == 1 {
      // TODO: font.large?
      text(size: 12pt, weight: "bold", {
        let ex = 7.95pt
        v(2.7 * ex, weak: true)
        [#number *#it.body*]
        v(2 * ex, weak: true)
      })
    } else if it.level == 2 {
      text(size: font.normal, weight: "bold", {
        let ex = 6.62pt
        v(2.70 * ex, weak: true)
        [#number *#it.body*]
        v(2.03 * ex, weak: true) // Original 1ex.
      })
    } else if it.level == 3 {
      text(size: font.normal, weight: "bold", {
        let ex = 6.62pt
        v(2.6 * ex, weak: true)
        [#number *#it.body*]
        v(1.8 * ex, weak: true) // Original -1em.
      })
    }
  }

  // Configure images and tables appearence.
  set figure.caption(separator: [:])
  show figure: set block(breakable: false)
  show figure.caption.where(kind: table): it => make_figure_caption(it)
  show figure.caption.where(kind: image): it => make_figure_caption(it)
  show figure.where(kind: image): it => make_figure(it)
  show figure.where(kind: table): it => make_figure(it, caption_above: true)

  // Math equation numbering and referencing.
  set math.equation(numbering: "(1)")
  show ref: it => {
    let eq = math.equation
    let el = it.element
    if el != none and el.func() == eq {
      let numb = numbering("1", ..counter(eq).at(el.location()))
      let color = rgb(0%, 8%, 45%) // Originally `mydarkblue`. :D
      let content = link(el.location(), text(fill: color, numb))
      [(#content)]
    } else {
      return it
    }
  }

  // Configure algorithm rendering.
  counter(figure.where(kind: "algorithm")).update(0)
  show figure.caption.where(kind: "algorithm"): it => {
    strong[#it.supplement #it.counter.display(it.numbering)]
    [ ]
    it.body
  }
  show figure.where(kind: "algorithm"): it => {
    place(top, float: true, block(breakable: false, width: 100%, {
      set block(spacing: 0em)
      line(length: 100%, stroke: (thickness: 0.08em))
      block(spacing: 0.4em, it.caption) // NOTE: No idea why we need it.
      line(length: 100%, stroke: (thickness: 0.05em))
      it.body
      line(length: 100%, stroke: (thickness: 0.08em))
    }))
  }

  let (
    theorem,
    lemma,
    corollary,
    remark,
    proposition,
    definition,
    example,
    proof,
    rules: theorem_rules,
  ) = default-theorems("theorem_group", lang: "en")
  show: theorem_rules


  // Render title.
  block(width: 5.5in, {
    // We need to define line widths to reuse them in spacing.
    let top-rule-width = 4pt
    let bot-rule-width = 1pt

    // Add some space based on line width.
    v(0.1in + top-rule-width / 2)
    // line(length: 100%, stroke: top-rule-width + black)
    align(center, text(size: 17pt, weight: "bold", [#title]))
    v(-bot-rule-width)
    // line(length: 100%, stroke: bot-rule-width + black)
  })

  v(0.25in)

  // Render authors.
  block(width: 100%, {
    set text(size: font.normal)
    set par(leading: 4.5pt)
    set par(spacing: 1.0em) // Original 11pt.
    make-authors(authors, affls)
    v(0.3in - 0.1in)
  })

  // Vertical spacing between authors and abstract.
  v(6.5pt) // Original 0.075in.

  // Render main body
  {
    // Display body.
    set text(size: font.normal)
    set par(leading: 0.55em)
    set par(leading: 0.43em)
    set par(spacing: 1.0em) // Original 11pt.
    doc

    // Display the bibliography, if any is given.
    if bibliography != none {
      if "title" not in bibliography-opts {
        bibliography-opts.title = "References"
      }
      if "style" not in bibliography-opts {
        bibliography-opts.style = "ieee"
      }
      // NOTE It is allowed to reduce font to 9pt (small) but there is not
      // small font of size 9pt in original sty.
      show std-bibliography: set text(size: font.small)
      set std-bibliography(..bibliography-opts)
      bibliography
    }
  }
}


#let mnf(
  title: [],
  authors: (authors, affls),
  keywords: (),
  date: auto,
  abstract: none,
  bibliography: none,
  bibliography-opts: (:),
  appendix: none,
  accepted: false,
  doc,
) = [
  #show: neurips2024.with(
    title: title,
    authors: authors,
    keywords: keywords,
    abstract: abstract,
    appendix: appendix,
    bibliography: bibliography,
    bibliography-opts: bibliography-opts,
    accepted: accepted,
  )

  #let (
    theorem,
    lemma,
    corollary,
    remark,
    proposition,
    definition,
    example,
    proof,
    rules: theorem_rules,
  ) = default-theorems("theorem_group", lang: "en")
  #show: theorem_rules

  #doc
]
