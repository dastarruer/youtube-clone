use axum::{Router, routing::get};

const PORT: i16 = 3000;

#[tokio::main]
async fn main() {
    let app = Router::new().route("/", get(|| async { "Hello world" }));

    let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{PORT}"))
        .await
        .unwrap();

    println!("Listening on {PORT}...");
    axum::serve(listener, app).await.unwrap();
}
