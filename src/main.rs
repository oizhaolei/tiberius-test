use std::env;

use dotenvy::dotenv;

use tiberius::{AuthMethod, Client, Config, EncryptionLevel};
use tokio::net::TcpStream;
use tokio_util::compat::TokioAsyncWriteCompatExt;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenv().expect(".env file not found");

    let mut config = Config::new();

    config.host(env::var("HOST")?);
    config.port(env::var("PORT")?.parse::<u16>()?);
    config.database(env::var("DATABASE")?);

    config.authentication(AuthMethod::sql_server(env::var("DB_USER")?,env::var("DB_PASSWORD")?));
    config.trust_cert(); // on production, it is not a good idea to do this
    config.encryption(EncryptionLevel::NotSupported);

    let tcp = TcpStream::connect(config.get_addr()).await?;
    tcp.set_nodelay(true)?;

    // To be able to use Tokio's tcp, we're using the `compat_write` from
    // the `TokioAsyncWriteCompatExt` to get a stream compatible with the
    // traits from the `futures` crate.
    let mut client = Client::connect(config, tcp.compat_write()).await?;

    let results = client
        .simple_query(env::var("SELECT")?)
        .await?
        .into_results()
        .await?;

    for val in results.iter() {
        // 取得した件数分ループする
        for inner in val.iter() {
            println!("inner: {:?}", inner);
            // id列の情報を取得
            if let Some(id) = inner.get::<i32, _>("userid") {
                print!("id = {} ", id);
            }
            // name列の情報を取得
            if let Some(name) = inner.get::<&str, _>("username") {
                println!("name = {}", name);
            }
        }
    }

    Ok(())
}
