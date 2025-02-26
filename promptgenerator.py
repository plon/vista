def generate_ocr_system_prompt(
    format_type="plain_text",
    pretty_formatting=False,
    original_formatting=True,
    language_detection=False,
    latex_math=True,
    target_language=None,
    error_correction=False,
    low_confidence_highlighting=False,
    contextual_grouping=False,
    accessibility_alt_text=False,
    smart_context=False,
):
    """
    Generates a system prompt for an OCR system based on the provided options.

    Parameters:
        format_type (str): The output format type. Options: "plain text", "json",
                           "html", "xml", "rtf".
        pretty_formatting (bool): Enable pretty formatting for improved readability.
        original_formatting (bool): Preserve the original formatting of the source.
        language_detection (bool): Enable language detection and optional translation.
        target_language (str): The target language for translation (if applicable).
        error_correction (bool): Enable error correction for OCR output.
        low_confidence_highlighting (bool): Highlight low-confidence OCR sections.
        contextual_grouping (bool): Enable intelligent grouping of related content.
        accessibility_alt_text (bool): Generate alt text for images for accessibility.
        smart_context (bool): Parse annotations and spatial clues for context.

    Returns:
        str: The generated OCR system prompt.
    """

    # Define output expectations for each format
    format_expectations = {
        "plain_text": (
            "Output the extracted content as plain text. Use line breaks to separate paragraphs."
        ),
        "html": (
            "Output the content as valid, well-structured HTML. Use semantic tags "
            "to represent elements: <h1>, <h2>, etc., for headings; <p> for paragraphs; "
            "<ul> and <li> for bullet points; <table>, <tr>, and <td> for tables. "
            "Ensure proper nesting and closing of tags."
        ),
        "json": (
            "Output the content as a structured JSON object. Use keys to represent "
            "content types (e.g., 'title', 'paragraph', 'list', 'table'). For lists, "
            "use arrays to group items. For tables, use an array of objects, where "
            "each object represents a row."
        ),
        "rtf": (
            "Output the content as an RTF document. Use RTF tags to represent formatting: "
            "\\b for bold (e.g., headings), \\i for italics, \\par for paragraphs, "
            "\\listtext for bullet points, and \\trowd and \\cell for tables. Ensure "
            "compatibility with standard RTF readers."
        ),
        "xml": (
            "Output the content as a well-formed XML document. Use custom tags to "
            "represent content types (e.g., <title>, <paragraph>, <list>, <table>). "
            "For lists, use nested <item> tags. For tables, use <row> and <cell> tags."
        ),
        "latex": (
            "Output the content as a LaTeX document. Use LaTeX commands to represent "
            "content elements: \\section{} and \\subsection{} for headings, \\textbf{} "
            "for bold text, \\begin{itemize} and \\item for bullet points, and "
            "\\begin{table} with \\hline for tables. Ensure mathematical expressions "
            "are properly formatted using math mode (e.g., $...$ for inline math and "
            "\\[ ... \\] for display math)."
        ),

    }

    # Start building the prompt
    prompt = "Process the provided content in the image. Follow these instructions:\n\n"

    # Add format-specific expectations
    prompt += f"{format_expectations.get(format_type, 'Invalid format type specified.')}\n\n"

    # Add optional features based on toggles
    if pretty_formatting:
        prompt += (
            "Reconstruct the text to improve readability. Remove unnecessary line breaks, adjust paragraphing, and ensure the output is polished and easy to read.\n\n"
        )
    # note that original formatting cannot be used with pretty formatting and vice versa
    if original_formatting:
        prompt += (
            "Preserve the source document's layout exactly as it appears. Retain all original line breaks, indentation, spacing, and alignment.\n\n"
        )

    if language_detection:
        if target_language:
            prompt += (
                f"Detect the text's language and translate it into {target_language}.\n\n"
            )
        else:
            prompt += (
                "Detect the text's language and retain it unless a target language is specified.\n\n"
            )

    if latex_math:
        prompt += "Convert math equations into LaTeX; For inline formulas, enclose the formula in $…$. For displayed formulas, use $$…$$.\n\n"

    if error_correction:
        prompt += (
            "Refine the OCR output by correcting recognition mistakes, fixing typographical errors, and improving grammar and context.\n\n"
        )

    if low_confidence_highlighting:
        prompt += (
            "Highlight eleements with low OCR confidence using the marker '[?]' to flag them for review.\n\n"
        )

    if contextual_grouping:
        prompt += (
            "Group related content intelligently. For example, combine captions with corresponding charts or diagrams to present cohesive blocks of information.\n\n"
        )

    if accessibility_alt_text:
        prompt += (
            "Generate descriptive alternative text (alt text) for images or graphical elements.\n\n"
        )

    if smart_context:
        prompt += (
            "Extract annotations, side notes, or comments. Include spatial clues to describe relationships, such as 'This caption appears below the image.'\n\n"
        )

    # Final instruction
    prompt += "Extract the content from the image, adhering to the instructions above. If any ambiguity arises, prioritize accuracy and mark uncertain sections for review."

    return prompt


# Example usage
if __name__ == "__main__":
    # Example configuration
    system_prompt = generate_ocr_system_prompt(
        # format_type="json",
        # pretty_formatting=True,
        # original_formatting=False,
        # language_detection=True,
        # target_language="English",
        # error_correction=True,
        # low_confidence_highlighting=True,
        # contextual_grouping=True,
        # accessibility_alt_text=True,
        # smart_context=True,
    )
    print(system_prompt)
