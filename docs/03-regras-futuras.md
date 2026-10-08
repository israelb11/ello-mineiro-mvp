# Regras de Negócio Futuras — Ello Mineiro

> Status: **planejamento**. Nada deste documento será implementado no código do MVP (Fase 1: cadastro e login). Ele registra as regras válidas para as próximas fases, de modo que a modelagem atual do banco não precise ser refeita.

## 1. Princípio: conta, perfil e vínculo são coisas distintas

| Conceito | O que é | Onde vive |
|---|---|---|
| **Conta** | Identidade e credencial (`user_login`, e-mail, senha) | `Usuarios` (Fase 1) |
| **Perfil** | O que a pessoa *pode fazer* (`Usuario`, `Aluno`, `Professor`, `Suporte`, `Administrativo`) | `Permissoes` + `Usuarios.permissao_nome` (Fase 1) |
| **Vínculo** | A *quais dados* a pessoa tem acesso (turma, matrículas, matérias) | Tabelas futuras (`Alunos`, `Turmas`, `Matriculas`...) |

Regra de ouro: **o perfil dá a capacidade e o vínculo dá o escopo dos dados.** Um aluno só vê notas se tiver matrícula ativa em uma turma; ter o perfil `Aluno` sozinho não basta.

## 2. Situação no MVP

- Todo cadastro público recebe o perfil padrão `Usuario`.
- `user_login` é um nome de usuário escolhido pelo usuário (RN01 de [01-requisitos.md](01-requisitos.md)).
- Os perfis `Aluno`, `Professor`, `Suporte` e `Administrativo` existem em `Permissoes`, mas nenhuma rota ou tela os atribui.
- O primeiro administrador é criado fora da aplicação (seed ou script).

## 3. Promoção de perfil (fase futura)

1. O usuário se cadastra normalmente (perfil `Usuario`).
2. O setor administrativo localiza a pessoa (busca por e-mail ou CPF) e **confere a identidade** (documento, comprovante de matrícula ou contrato).
3. O administrativo atribui o perfil e cria o vínculo institucional.
4. A operação é registrada em auditoria (quem, quando, de qual perfil para qual).

Pontos a definir:
- Quem pode promover? Só `Administrativo`, ou também `Suporte`? A promoção **a** `Administrativo` deve ter regra mais rígida (ex.: somente outro administrador).
- Exigir **confirmação de e-mail** antes de qualquer promoção, para impedir cadastro com o e-mail de terceiros.
- Rebaixamento e desligamento: a conta passa a `ativo = false` (RN03) ou volta ao perfil `Usuario`; o histórico acadêmico é preservado.
- Um usuário pode ter mais de um perfil? (ex.: professor que também é responsável por um aluno). Hoje a modelagem permite **1 perfil** (RN02). Se for necessário N perfis, criar a tabela `Usuario_Permissoes` (N:N) e migrar o dado de `permissao_nome`.

## 4. Matrícula e registro funcional (identificadores institucionais)

Eles **não** são o `user_login`. São emitidos pela escola, na promoção, e armazenados em tabelas próprias:

| Tabela futura | Campos principais | Observação |
|---|---|---|
| `Alunos` | `usuario_id` (PK/FK), `matricula` (UNIQUE), `data_ingresso` | Padrão **X** |
| `Funcionarios` | `usuario_id` (PK/FK), `registro` (UNIQUE), `setor`, `data_admissao` | Padrão **Y** |

### Padrões X e Y (a definir pela escola)
Exemplos apenas ilustrativos:
- Aluno (X): `AAAA` + sequência de 6 dígitos → `2026000123`
- Funcionário (Y): `F` + sequência de 5 dígitos → `F00042`

Requisitos para qualquer padrão:
- Único, imutável após emitido e **sem dados pessoais** (nada de CPF ou data de nascimento).
- Gerado no **backend, dentro de transação**, a partir de uma tabela contador (ex.: `Sequencias(tipo, ano, ultimo_numero)`), com bloqueio da linha (`SELECT ... FOR UPDATE`) para evitar duplicidade em acessos simultâneos.
- Emitido apenas na promoção, nunca antes. Assim não existem números "órfãos" de pessoas não reconhecidas pela escola.

### Login por matrícula (opcional)
A matrícula/registro pode ser aceita como identificador de login adicional. Basta consultar `Alunos`/`Funcionarios` para achar o `usuario_id`; a tabela `Usuarios` não muda.

## 5. Vínculo acadêmico

Tabelas previstas (esboço, sem detalhamento): `Turmas`, `Materias`, `Matriculas` (aluno ↔ turma), `Professor_Turma`, `Notas`, `Presencas`, `Calendario`.

Regras:
- Aluno consulta apenas **as próprias** notas e presenças, e só de turmas em que tem matrícula ativa.
- Professor lança notas e faltas apenas nas turmas e matérias a que está vinculado.
- A autorização é verificada **no backend**, por perfil **e** por vínculo, em cada rota.
- O perfil `Usuario` enxerga somente conteúdo público (ex.: calendário escolar).

## 6. LGPD e menores de idade

- Coletar o mínimo no cadastro público: CPF e RG são **opcionais** e só devem ser exigidos quando necessários (promoção ou matrícula).
- Alunos podem ser menores de 18 anos: o tratamento de dados exige **consentimento específico de um dos pais ou responsável legal** (LGPD, art. 14). Prever o cadastro do responsável e o registro do consentimento.
- Definir prazo de retenção e rotina de anonimização para contas desligadas.
- Registrar acessos a dados sensíveis (quem consultou notas e dados pessoais).
- Responder a pedidos de titular (acesso, correção, exclusão) dentro das regras legais.
- Nunca expor CPF, RG ou notas em respostas de API que não precisem deles.

## 7. Evoluções de segurança

- Confirmação de e-mail e recuperação de senha por link com expiração.
- Autenticação em dois fatores para perfis administrativos.
- Revogação de tokens (lista de bloqueio ou *refresh token* rotativo).
- Bloqueio temporário de conta após tentativas de login falhas.
- Trilha de auditoria para alterações de perfil.

## 8. Impacto no banco: o que o MVP já deixa pronto

| Item da Fase 1 | Por que favorece o futuro |
|---|---|
| `Usuarios.id` como chave estável | Base de todas as FKs futuras (`Alunos`, `Funcionarios`, `Matriculas`) |
| `Permissoes` com todos os perfis | Promoção é só alterar `permissao_nome` |
| `user_login` independente da matrícula | Matrícula e registro entram sem alterar `Usuarios` |
| `ativo` e exclusão lógica | Desligamento sem perder histórico |
| `Endereco` 1:N | Reaproveitado para alunos, funcionários e responsáveis |

## 9. Perguntas a resolver antes dessas fases

1. Formato oficial dos padrões X e Y.
2. Quem pode promover cada perfil?
3. Um usuário pode acumular perfis (1 ou N)?
4. Como será a verificação de identidade (presencial, documento, convite)?
5. Haverá perfil de **Responsável** para alunos menores de idade?
6. Prazo de retenção de dados de contas desligadas.
