# Ingest Client

-------
This is the repository for the Ingest Client application. This cross-platform application will enable users of the Ingest platform to perform high-speed UDP file transfers into the Ingest platform - or other other clients. This is INL's response to Globus, an open-source alternative designed to enable high-speed file tranfers for all.

### What makes us different from Globus?
Ingest focuses heavily on collecting metadata at the time of data ingestion. By focusing file transfers by assigning them to projects, we are able to enforce metadata collection at time of upload. We streamline the process as much as possible to make data collection and transfer as easy as possible. We are also entirely open-source and encourage users to run their own Ingest servers if they cannot afford to use the managed service provided by INL. 


## Building from Source

-----
### Requirements:

- Rust 1.7x.x
- Cargo build tool

1. Simply run `cargo build` in the main directory and your program will be compiled.