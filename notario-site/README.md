# NOTÁRIO Website - Deploy no Netlify

## 📁 Estrutura Criada

```
Notario/
└── notario-site/
    ├── index.html      (Landing page)
    ├── privacy.html    (Política de Privacidade)
    └── terms.html      (Termos de Serviço)
```

## 🚀 Como Fazer Deploy no Netlify

### Opção 1: Novo Site no Netlify

1. Vá para https://app.netlify.com/
2. Clique em **"Add new site"** → **"Deploy manually"**
3. Arraste a pasta `notario-site` para o Netlify
4. Pronto! O site será publicado

### Opção 2: Via Git (Recomendado)

1. Fazer commit da pasta:

```bash
cd "C:\Users\agata\OneDrive\Documents\Gitchi Habi\Notario"
git add notario-site/
git commit -m "feat: adicionar site do NOTÁRIO"
git push
```

2. No Netlify:
   - **Add new site** → **Import an existing project**
   - Conectar ao repositório
   - **Base directory:** `notario-site`
   - **Publish directory:** `notario-site`
   - Deploy!

## 🔗 URLs Finais

Depois do deploy, você terá algo como:

```
https://notario.netlify.app
```

Ou pode usar um subdomínio personalizado.

## 📝 Para Configurar no Firebase

Use estes URLs no Firebase Console:

- **Página inicial do aplicativo:**

  ```
  https://notario.netlify.app
  ```

- **Link da Política de Privacidade:**

  ```
  https://notario.netlify.app/privacy.html
  ```

- **Link dos Termos de Serviço:**
  ```
  https://notario.netlify.app/terms.html
  ```

## ✅ Checklist

- [x] Pasta `notario-site` criada
- [x] `index.html` (landing page)
- [x] `privacy.html` (privacidade)
- [x] `terms.html` (termos)
- [ ] Fazer commit
- [ ] Deploy no Netlify
- [ ] Configurar no Firebase Console

## 🎨 O Site Inclui

- Design moderno com gradiente roxo/azul
- Hero section impactante
- 6 features bem explicadas
- Links para Privacy e Terms
- Footer completo
- Totalmente responsivo

---

**Próxima ação:** Fazer commit e deploy no Netlify!
