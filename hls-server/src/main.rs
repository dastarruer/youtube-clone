use axum::{Router, extract::Path, response::IntoResponse, routing::get};

const PORT: i16 = 3000;

#[tokio::main]
async fn main() {
    let app = Router::new().route("/", get(root));

    let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{PORT}"))
        .await
        .unwrap();

    println!("Listening on {PORT}...");
    axum::serve(listener, app).await.unwrap();
}

async fn root() -> impl IntoResponse {
    let source = Path("./videos/test.mp4");
    let destination = Path("./videos/converted.mp4");
    
    ffmpeg_next::init().expect(msg)

    "TODO"
}
