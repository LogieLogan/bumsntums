Prioritize Absolute Completeness: My primary focus will be ensuring that any code block I provide is fully runnable and complete within its defined scope (e.g., a full method, a full class definition if multiple parts change significantly, or a specific widget build block).
No Placeholders/Ellipses (Strict Enforcement): I will treat ..., /* ... */, and any form of placeholder within code blocks as strictly forbidden, exactly as you instructed. If I cannot provide the actual code for a section within the requested scope, I will omit that section or the entire block if necessary, rather than provide a broken placeholder.
Context Over Excessive Snippeting: While targeted fixes are important, if modifying a few lines within a method risks confusion or requires understanding the surrounding unchanged lines for context, I will provide the entire method as the targeted fix. This reduces the chance of me accidentally removing necessary code or using placeholders.
Internal Review Simulation: Before outputting code, I will perform a stricter internal check specifically looking for:
Any ... or /* */ placeholders.
Incomplete logic or variables.
Code that relies on context not provided within the same block.
Ensuring I haven't replaced existing, correct code (like the analytics line) with a summary comment.
Direct Feedback Loop: Please continue to point out immediately when I make this mistake, as you just did. This immediate correction is the most effective way to reinforce the requirement.

Avoid using ellipses (...), placeholders, or shortened forms in code. i.e do ot do this child: Row( /* ... Week navigation buttons and text ... */ ), either provide the row or leave this part out completely and provide a more targeted fix 

If a method/fucntion/file has no changes dont output the unchnaged code

Only provide updated and new code in its full form (e.g. dont break it up with placeholders)

Each method has its own code block if updating multiple methods put the chnages to each method in a new code block with a short explanation

ONLY provide the entire method if you are actually providing all the code (no placeholders)

NO PLACEHOLDER CODE ONLY FULL FUNCTIONING CODE

If replacing constants, enums, or config values, provide the updated constant along with its context (e.g., full block or section).

Do not include explanation text in code blocks unless absolutely necessary (e.g., a comment to prevent misuse of logic).

Always use real, runnable code—no pseudo-code, placeholder variables, or incomplete logic.
