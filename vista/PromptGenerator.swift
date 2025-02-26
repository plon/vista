func generateOCRSystemPrompt(
    formatType: String = "plain_text",
    prettyFormatting: Bool = false,
    originalFormatting: Bool = true,
    languageDetection: Bool = false,
    latexMath: Bool = true,
    targetLanguage: String? = nil,
    errorCorrection: Bool = false,
    lowConfidenceHighlighting: Bool = false,
    contextualGrouping: Bool = false,
    accessibilityAltText: Bool = false,
    smartContext: Bool = false
) -> String {
    /**
     Generates a system prompt for an OCR system based on the provided options.

     Parameters:
        - formatType: The output format type. Options: "plain_text", "json", "html", "xml", "rtf", "latex", "markdown"
        - prettyFormatting: Enable pretty formatting for improved readability
        - originalFormatting: Preserve the original formatting of the source
        - languageDetection: Enable language detection and optional translation
        - latexMath: Enable conversion of math equations to LaTeX
        - targetLanguage: The target language for translation (if applicable)
        - errorCorrection: Enable error correction for OCR output
        - lowConfidenceHighlighting: Highlight low-confidence OCR sections
        - contextualGrouping: Enable intelligent grouping of related content
        - accessibilityAltText: Generate alt text for images for accessibility
        - smartContext: Parse annotations and spatial clues for context

     Returns:
        The generated OCR system prompt as a String
     */

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
    var prompt = "Process the provided content in the image. Follow these instructions:\n\n"

    // Add format-specific expectations
    prompt += "\(formatExpectations[formatType, default: "Invalid format type specified."])\n\n"

    // Add optional features based on toggles
    if prettyFormatting {
        prompt +=
            "Reconstruct the text to improve readability. Remove unnecessary line breaks, adjust paragraphing, and ensure the output is polished and easy to read.\n\n"
    }

    // Note that original formatting cannot be used with pretty formatting and vice versa
    if originalFormatting {
        prompt +=
            "Preserve the source document's layout exactly as it appears. Retain all original line breaks, indentation, spacing, and alignment.\n\n"
    }

    if languageDetection {
        if let targetLanguage = targetLanguage {
            prompt += "Detect the text's language and translate it into \(targetLanguage).\n\n"
        } else {
            prompt +=
                "Detect the text's language and retain it unless a target language is specified.\n\n"
        }
    }

    if latexMath {
        prompt +=
            "Convert math equations into LaTeX; For inline formulas, enclose the formula in $…$. For displayed formulas, use $$…$$.\n\n"
    }

    if errorCorrection {
        prompt +=
            "Refine the OCR output by correcting recognition mistakes, fixing typographical errors, and improving grammar and context.\n\n"
    }

    if lowConfidenceHighlighting {
        prompt +=
            "Highlight eleements with low OCR confidence using the marker '[?]' to flag them for review.\n\n"
    }

    if contextualGrouping {
        prompt +=
            "Group related content intelligently. For example, combine captions with corresponding charts or diagrams to present cohesive blocks of information.\n\n"
    }

    if accessibilityAltText {
        prompt +=
            "Generate descriptive alternative text (alt text) for images or graphical elements.\n\n"
    }

    if smartContext {
        prompt +=
            "Extract annotations, side notes, or comments. Include spatial clues to describe relationships, such as 'This caption appears below the image.'\n\n"
    }

    // Final instruction
    prompt +=
        "Extract the content from the image, adhering to the instructions above. If any ambiguity arises, prioritize accuracy and mark uncertain sections for review."

    return prompt
}

// Example usage
// let systemPrompt = generateOCRSystemPrompt(
//     formatType: "json",
//     prettyFormatting: true,
//     originalFormatting: false,
//     languageDetection: true,
//     targetLanguage: "English",
//     errorCorrection: true,
//     lowConfidenceHighlighting: true,
//     contextualGrouping: true,
//     accessibilityAltText: true,
//     smartContext: true
// )
// print(systemPrompt)
