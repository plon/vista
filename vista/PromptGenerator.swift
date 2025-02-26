func generateOCRSystemPrompt(
    formatType: String = "plain_text",
    prettyFormatting: Bool = false,
    originalFormatting: Bool = true,
    outputLanguage: String = "",
    latexMath: Bool = true,
    spellCheck: Bool = false,
    lowConfidenceHighlighting: Bool = false,
    contextualGrouping: Bool = false,
    accessibilityAltText: Bool = false,
    smartContext: Bool = false
) -> String {
    // Define output expectations for each format
    let formatExpectations: [String: String] = [
        "plain_text":
            "Output the extracted content as plain text. Use line breaks to separate paragraphs.",
        "html": "Output the content as valid, well-structured HTML. Use semantic tags "
            + "to represent elements: <h1>, <h2>, etc., for headings; <p> for paragraphs; "
            + "<ul> and <li> for bullet points; <table>, <tr>, and <td> for tables. "
            + "Ensure proper nesting and closing of tags.",
        "json": "Output the content as a structured JSON object. Use keys to represent "
            + "content types (e.g., 'title', 'paragraph', 'list', 'table'). For lists, "
            + "use arrays to group items. For tables, use an array of objects, where "
            + "each object represents a row.",
        "rtf": "Output the content as an RTF document. Use RTF tags to represent formatting: "
            + "\\b for bold (e.g., headings), \\i for italics, \\par for paragraphs, "
            + "\\listtext for bullet points, and \\trowd and \\cell for tables. Ensure "
            + "compatibility with standard RTF readers.",
        "xml": "Output the content as a well-formed XML document. Use custom tags to "
            + "represent content types (e.g., <title>, <paragraph>, <list>, <table>). "
            + "For lists, use nested <item> tags. For tables, use <row> and <cell> tags.",
        "latex": "Output the content as a LaTeX document. Use LaTeX commands to represent "
            + "content elements: \\section{} and \\subsection{} for headings, \\textbf{} "
            + "for bold text, \\begin{itemize} and \\item for bullet points, and "
            + "\\begin{table} with \\hline for tables. Ensure mathematical expressions "
            + "are properly formatted using math mode (e.g., $...$ for inline math and "
            + "\\[ ... \\] for display math).",
        "markdown": "Output the content as a Markdown document. Use Markdown syntax to represent "
            + "content elements: '#' for headings, '**' for bold text, '*' or '-' for bullet points, "
            + "and '|' for tables. Ensure proper indentation for nested lists and use backticks "
            + "(```) for code blocks.",
    ]

    // Start building the prompt
    var prompt = "Process the provided content in the image. Follow these instructions:\n"

    // Start instructions tag
    prompt += "<instructions>\n"

    // Add format-specific expectations
    prompt += "\(formatExpectations[formatType, default: "Invalid format type specified."])\n\n"

    // Add optional features based on toggles
    if prettyFormatting {
        prompt +=
            "Reconstruct the text to improve readability. Remove unnecessary line breaks, adjust paragraphing, and ensure the output is polished and easy to read.\n\n"
    }

    if originalFormatting {
        prompt +=
            "Preserve the source document's layout exactly as it appears. Retain all original line breaks, indentation, spacing, and alignment.\n\n"
    }

    if !outputLanguage.isEmpty {
        prompt += "Detect the text's language and translate it into \(outputLanguage).\n\n"
    }

    if latexMath && formatType != "latex" {
        prompt +=
            "Convert math equations into LaTeX; For inline formulas, enclose the formula in $…$. For displayed formulas, use $$…$$.\n\n"
    }

    if spellCheck {
        prompt +=
            "Fix OCR and spelling errors, using context of surrounding text when helpful.\n\n"
    }

    if lowConfidenceHighlighting {
        prompt +=
            "Highlight elements with low OCR confidence using the marker '[?]' to flag them for review.\n\n"
    }

    if contextualGrouping {
        prompt +=
            "Group related content intelligently. For example, combine captions with corresponding charts or diagrams to present cohesive blocks of information.\n\n"
    }

    if accessibilityAltText {
        prompt +=
            "Generate descriptive alternative text (alt text) for images or graphical elements using the format [alt text: description].\n\n"
    }

    if smartContext {
        prompt +=
            "Extract annotations, side notes, or comments. Include spatial clues to describe relationships, such as 'This caption appears below the image.'\n\n"
    }

    // End instructions tag
    prompt += "</instructions>\n"

    // Final instruction
    prompt += "Extract the content from the image, adhering to the instructions above."

    return prompt
}
