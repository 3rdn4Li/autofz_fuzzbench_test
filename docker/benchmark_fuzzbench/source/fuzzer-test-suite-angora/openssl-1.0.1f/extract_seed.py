import zipfile
import os
CORPUS_ELEMENT_BYTES_LIMIT = 1 * 1024 * 1024
with zipfile.ZipFile("/out/x509_seed_corpus.zip") as zip_file:
        # Unpack seed corpus recursively into the root of the main corpus
        # directory.
        idx = 0
        for seed_corpus_file in zip_file.infolist():
            if seed_corpus_file.filename.endswith('/'):
                # Ignore directories.
                continue

            # Allow callers to opt-out of unpacking large files.
            if seed_corpus_file.file_size > CORPUS_ELEMENT_BYTES_LIMIT:
                continue

            output_filename = f'{idx:016d}'
            output_file_path = os.path.join("/seeds/fuzzer-test-suite/openssl-1.0.1f", output_filename)
            zip_file.extract(seed_corpus_file, output_file_path)
            idx += 1