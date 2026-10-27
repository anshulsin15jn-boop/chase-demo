# Approved icon artwork

Only the standalone icon supplied for this update is approved as a bitmap asset. IconArtwork.png is a cleaned opaque RGB source with pixels identical to the supplied 512 by 512 artwork. The AppIcon catalog contains the nine required iPhone and marketing sizes. Resizing preserves the full square composition; iOS supplies its own rounded mask. The 1024 size is an upscale of the provided resolution.

approved-icon-sha256.json restricts image tracking to these reviewed assets. Comparison screenshots remain outside the repository and are never used by the build. The historical generate_icon.py workflow command now validates these assets and does not create replacement artwork.
