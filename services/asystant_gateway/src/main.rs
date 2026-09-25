use std::{env, sync::Arc};
use actix_cors::Cors;
use actix_web::{App, HttpServer, web};
use asystant_gateway::{
    config::Config, handler, provider::ProviderClient, repository::PoolConfig,
    service::GatewayService,
};

#[actix_web::main]
async fn main() -> anyhow::Result<()> {
    let mode = env::args().nth(1);
    if let Some(mode) = mode.as_deref()
        && mode != "--migrate-only"
        && mode != "--serve"
    {
        anyhow::bail!("usage: asystant_gateway [--migrate-only | --serve]");
    }
    if mode.as_deref() == Some("--migrate-only") {
        PoolConfig::connect(&env::var("DATABASE_URL")?)?.migrate()?;
        return Ok(());
    }
    let config = Config::from_env()?;
    let pool = if mode.as_deref() == Some("--serve") {
        PoolConfig::connect(&env::var("DATABASE_URL")?)?
    } else {
        PoolConfig::new(&env::var("DATABASE_URL")?)?
    };
    let service = Arc::new(GatewayService {
        config: config.clone(),
        pool,
        provider: Arc::new(ProviderClient::new()?),
    });
    HttpServer::new(move || {
        let mut cors = Cors::default()
            .allowed_methods(vec!["GET", "POST"])
            .allowed_headers(vec!["Authorization", "Content-Type"])
            .max_age(600);
        for origin in &config.origins {
            cors = cors.allowed_origin(origin)
        }
        App::new()
            .wrap(cors)
            .app_data(web::JsonConfig::default().limit(262144))
            .app_data(web::Data::new(Arc::clone(&service)))
            .configure(handler::routes)
    })
    .shutdown_timeout(130)
    .bind(env::var("ASYSTANT_BIND").unwrap_or_else(|_| "127.0.0.1:8787".into()))?
    .run()
    .await?;
    Ok(())
}
