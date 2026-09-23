# Walk revision 04 QA

- Input order: existing Walk sheet for edit, approved idle for identity, generated layout guide for spacing. GPT generated the strip; sprite-gen extracted, composed, previewed, inspected, and scored it.
- Output: eight transparent 192x192 frames at 8 fps. Each extracted character is 156 pixels tall, with crown at y=18 and soles at y=173. Structural score was 94; no edge-contact frames were found.
- Human motion verdict: **fail**. Frames 1/5, 2/6, 3/7, and 4/8 follow very similar lower-body silhouettes. The key requested change, unmistakable alternate anatomical foot contact, is not established. The motion report also leaves stance and stride unverified without single-foot contact evidence.
- The existing Walk source and game integration remain untouched. This run is a reviewable candidate, not a runtime replacement.
