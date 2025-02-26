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
            "Output as plain text while preserving readability and structure. Use line breaks to separate paragraphs.",

        "html":
            "Convert to semantic HTML5 that preserves both structure and presentation. Use appropriate "
            + "tags (<header>, <article>, <section>, <p>, <strong>, <em>, etc.) and attributes "
            + "(class, style) to maintain visual hierarchy and formatting. Ensure valid DOM structure "
            + "and accessibility.",

        "json":
            "Structure as a semantic JSON document with clear hierarchy. Include 'type', 'content', "
            + "and 'style' properties to capture structure and formatting. Example: "
            + "{'type': 'paragraph', 'content': 'text', 'style': {'bold': true}}. Maintain "
            + "relationships between elements.",

        "rtf":
            "Generate a complete RTF document using standard control codes (\\b, \\i, \\par, etc.) "
            + "to preserve formatting. Include document-level properties and styling. Handle "
            + "complex elements like tables (\\trowd, \\cell) and lists while maintaining "
            + "compatibility.",

        "xml":
            "Create a semantic XML structure with clear hierarchy. Use elements for content "
            + "(<paragraph>, <list>, <table>) and attributes for styling (font-weight, "
            + "font-style). Include metadata and maintain valid XML syntax. Example: "
            + "<text style='bold'>content</text>.",

        "latex":
            "Generate a complete LaTeX document with appropriate structure and formatting. "
            + "Use semantic commands (\\section{}, \\textbf{}, \\begin{itemize}, etc.) and "
            + "proper environments. Handle math mode appropriately ($...$ for inline, "
            + "\\[ ... \\] for display). Include necessary packages.",

        "markdown":
            "Convert to idiomatic Markdown that balances readability with formatting fidelity. "
            + "Use native syntax (# for headings, ** for bold, * for italic, - for lists, "
            + "| for tables) where possible. Fall back to HTML spans for complex formatting. "
            + "Maintain clear document structure.",
    ]

    // Start building the prompt
    var prompt = "Process the provided content in the image. Follow these instructions:\n"

    // Start instructions tag
    prompt += "<instructions>\n"

    // Add format-specific expectations
    prompt += "\(formatExpectations[formatType, default: "Invalid format type specified."])\n\n"

    prompt +=
        "Preserve all visual styling (bold, italic, alignment, etc.) using the appropriate syntax and capabilities of the target format.\n\n"

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
            "Fix all OCR and spelling errors while maintaining any styling/formatting as specified in the above instructions. Use context of surrounding text when needed for corrections.\n\n"
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
