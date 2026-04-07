# World Pin — Arquitetura

## Visão Geral

Aplicativo Flutter para marcar e visualizar países visitados em um mapa interativo.

---

## Gerenciamento de Estado

**Escolha: Riverpod (flutter_riverpod)**

### Por quê Riverpod?
- Estado persistente e compartilhado entre telas (países visitados)
- Não depende de `BuildContext` para ler estado
- Seguro em tempo de compilação — sem erros em runtime por provider não encontrado
- Fácil de testar
- Sem boilerplate excessivo para o porte desse app

### Padrão de uso
- `StateNotifierProvider` ou `AsyncNotifierProvider` para listas e operações assíncronas
- `Provider` para valores derivados (ex: contagem de países visitados)
- `Ref` para injeção de dependências entre providers

---

## Arquitetura de Pastas

```
lib/
  features/
    map/
      presentation/
        pages/
          map_page.dart
        widgets/
          world_map_widget.dart
          country_tooltip_widget.dart
      providers/
        map_provider.dart
    countries/
      data/
        countries_repository.dart     # leitura e escrita local
        local_storage_service.dart    # abstração do shared_preferences
      domain/
        country.dart                  # modelo Country
      presentation/
        pages/
          country_list_page.dart
        widgets/
          country_tile_widget.dart
      providers/
        countries_provider.dart       # lista de países visitados
  shared/
    theme/
      app_theme.dart
    widgets/
      (widgets reutilizáveis)
  main.dart
  app.dart                            # MaterialApp + ProviderScope
```

---

## Modelo de Dados

```dart
class Country {
  final String code;       // ISO 3166-1 alpha-2 (ex: "BR", "FR")
  final String name;       // nome em português
  final bool visited;
}
```

---

## Mapa

**Escolha: flutter_map + GeoJSON**

- `flutter_map` para renderização do mapa com pan/zoom
- Camada GeoJSON com bordas dos países
- Países visitados coloridos com cor de destaque
- Tap no país abre opção de marcar/desmarcar

### Alternativa considerada e descartada
- SVG interativo (`flutter_svg`) — menos suporte a interações complexas por país

---

## Persistência

**Escolha: shared_preferences**

- Salva a lista de códigos ISO dos países visitados localmente
- Simples e suficiente para MVP
- Caminho de migração futuro: Supabase ou Firebase para sync em nuvem

---

## Dependências Planejadas

| Pacote                  | Versão  | Uso                              |
|-------------------------|---------|----------------------------------|
| `flutter_riverpod`      | ^2.x    | gerenciamento de estado          |
| `riverpod_annotation`   | ^2.x    | geração de código para providers |
| `flutter_map`           | ^7.x    | mapa interativo                  |
| `latlong2`              | ^0.9.x  | coordenadas geográficas          |
| `shared_preferences`    | ^2.x    | persistência local               |
| `build_runner`          | ^2.x    | geração de código (dev)          |

---

## Decisões em Aberto

- [ ] Fonte dos dados GeoJSON dos países (arquivo local em assets ou CDN?)
- [ ] Suporte a múltiplas viagens por país (data, fotos, notas)?
- [ ] Idioma da lista de países (português ou inglês como base?)
- [ ] Tela inicial: mapa ou lista de países?
