// Учебный REST mock-server для ПР4/ПР5. Node.js 18+, без npm-пакетов.
const http = require('http');
const fs = require('fs');
const path = require('path');
const args = process.argv.slice(2);
const arg = (n, d) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : d; };
const port = Number(arg('--port', '8080'));
const origin = arg('--origin', 'http://localhost:5555');
const dbFile = path.join(__dirname, 'mock-data.json');
const now = () => new Date().toISOString();

function seed() {
  return {
    authors: [
      { id: 1, fullName: 'Толстой Л. Н.', birthYear: 1828, country: 'Россия', deletedAt: null },
      { id: 2, fullName: 'Оруэлл Дж.', birthYear: 1903, country: 'Великобритания', deletedAt: null },
    ],
    genres: [
      { id: 1, name: 'Роман', description: 'Крупная форма повествования', deletedAt: null },
      { id: 2, name: 'Антиутопия', description: 'Жанр о нежелательном обществе', deletedAt: null },
    ],
    publishers: [
      { id: 1, name: 'АСТ', city: 'Москва', foundedYear: 1990, deletedAt: null },
      { id: 2, name: 'Penguin', city: 'London', foundedYear: 1935, deletedAt: null },
    ],
    readers: [
      { id: 1, fullName: 'Анна Читатель', email: 'anna.reader@example.com', phone: '+7 900 111-11-11', card: { id: 1, number: 'RC-000001', issuedAt: '2026-01-15T00:00:00Z', expiresAt: '2027-01-15T00:00:00Z' }, deletedAt: null },
      { id: 2, fullName: 'Смирнов П. А.', email: 'smirnov@example.com', phone: '+7 900 000-00-00', card: { id: 2, number: 'RC-000002', issuedAt: '2026-01-15T00:00:00Z', expiresAt: '2027-01-15T00:00:00Z' }, deletedAt: null },
    ],
    books: [
      { id: 1, title: 'Война и мир', isbn: '978-5-17-118366-4', year: 1869, pages: 1300, publisherId: 1, authorIds: [1], genreIds: [1], copiesTotal: 4, copiesAvailable: 2, createdAt: now(), deletedAt: null },
      { id: 2, title: '1984', isbn: '978-0-452-28423-4', year: 1949, pages: 328, publisherId: 2, authorIds: [2], genreIds: [2], copiesTotal: 1, copiesAvailable: 0, createdAt: now(), deletedAt: null },
    ],
    loans: [],
    users: [
      { id: 1, username: 'reader', name: 'Анна Читатель', password: 'Reader1!', role: 'reader', readerId: 1 },
      { id: 2, username: 'librarian', name: 'Иван Библиотекарь', password: 'Librarian1!', role: 'librarian', readerId: null },
      { id: 3, username: 'admin', name: 'Ольга Администратор', password: 'Admin1!', role: 'admin', readerId: null },
    ],
  };
}

let db;
try { db = fs.existsSync(dbFile) ? JSON.parse(fs.readFileSync(dbFile, 'utf8')) : seed(); }
catch (_) { db = seed(); }
// Миграция старого mock-data.json, если он был создан предыдущей версией.
if (!Array.isArray(db.users)) db.users = seed().users;
if (!Array.isArray(db.loans)) db.loans = [];
if (!Array.isArray(db.readers)) db.readers = seed().readers;
const readerUser = db.users.find(u => u.username === 'reader');
if (readerUser && !readerUser.readerId) {
  let anna = db.readers.find(r => r.email === 'anna.reader@example.com');
  if (!anna) {
    anna = seed().readers[0];
    anna.id = nextId(db.readers);
    anna.card.id = anna.id;
    db.readers.push(anna);
  }
  readerUser.readerId = anna.id;
  readerUser.name = anna.fullName;
}
function save() { fs.writeFileSync(dbFile, JSON.stringify(db, null, 2), 'utf8'); }
save();

const tokens = new Map();
function tokenFor(u) { const t = 'token-' + u.id + '-' + Date.now(); tokens.set(t, u.id); return t; }
function currentUser(req) {
  const h = req.headers.authorization || '';
  const id = tokens.get(h.startsWith('Bearer ') ? h.slice(7) : '');
  return db.users.find(u => u.id === id) || null;
}
function safeUser(u) { return { id: u.id, username: u.username, name: u.name, role: u.role, readerId: u.readerId ?? null }; }
function cors(res) {
  res.setHeader('Access-Control-Allow-Origin', origin);
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Max-Age', '86400');
}
function send(res, status, data) {
  cors(res); res.statusCode = status;
  if (data === undefined) { res.end(); return; }
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  res.end(JSON.stringify(data));
}
function body(req) {
  return new Promise((ok, bad) => {
    let s = '';
    req.on('data', c => s += c);
    req.on('end', () => { try { ok(s ? JSON.parse(s) : {}); } catch (e) { bad(e); } });
  });
}
function nextId(a) { return a.reduce((m, x) => Math.max(m, Number(x.id) || 0), 0) + 1; }
function expandBook(b) {
  return {
    ...b,
    publisher: db.publishers.find(x => x.id === b.publisherId) || null,
    authors: db.authors.filter(x => b.authorIds.includes(x.id)).map(({ id, fullName }) => ({ id, fullName })),
    genres: db.genres.filter(x => b.genreIds.includes(x.id)).map(({ id, name }) => ({ id, name })),
  };
}
function publicItem(resource, x) { return resource === 'books' ? expandBook(x) : x; }
function librarianOnly(me, res) { if (me.role !== 'librarian') { send(res, 403, { message: 'Это действие доступно только библиотекарю' }); return false; } return true; }
function adminOnly(me, res) { if (me.role !== 'admin') { send(res, 403, { message: 'Это действие доступно только администратору' }); return false; } return true; }

async function main(req, res) {
  cors(res);
  if (req.method === 'OPTIONS') return send(res, 204);
  const u = new URL(req.url, `http://${req.headers.host}`);
  if (u.pathname === '/api/__health') return send(res, 200, { status: 'ok' });
  if (!u.pathname.startsWith('/api/')) return send(res, 404, { message: 'Не найдено' });

  // Публичная аутентификация.
  if (u.pathname === '/api/auth/login' && req.method === 'POST') {
    const d = await body(req);
    const user = db.users.find(x => x.username === d.username && x.password === d.password);
    if (!user) return send(res, 401, { message: 'Неверный логин или пароль' });
    return send(res, 200, { accessToken: tokenFor(user), refreshToken: 'study-refresh-' + user.id, user: safeUser(user) });
  }
  if (u.pathname === '/api/auth/register' && req.method === 'POST') {
    const d = await body(req);
    if (!d.username || !d.name || !d.password) return send(res, 422, { message: 'Заполните обязательные поля', errors: {} });
    if (String(d.password).length < 8 || !/[0-9]/.test(d.password) || !/[\W_]/.test(d.password)) {
      return send(res, 422, { message: 'Пароль не соответствует требованиям', errors: { password: 'Минимум 8 символов, цифра и специальный символ' } });
    }
    if (db.users.some(x => x.username === d.username)) return send(res, 422, { message: 'Такой логин уже занят', errors: { username: 'Логин уже используется' } });
    const readerId = nextId(db.readers);
    const reader = {
      id: readerId,
      fullName: String(d.name).trim(),
      email: `${String(d.username).trim()}@library.local`,
      phone: 'Не указан',
      card: { id: readerId, number: `RC-${String(readerId).padStart(6, '0')}`, issuedAt: now(), expiresAt: new Date(Date.now() + 365 * 86400000).toISOString() },
      deletedAt: null,
    };
    db.readers.push(reader);
    const user = { id: nextId(db.users), username: String(d.username).trim(), name: String(d.name).trim(), password: d.password, role: 'reader', readerId };
    db.users.push(user); save();
    return send(res, 201, { accessToken: tokenFor(user), refreshToken: 'study-refresh-' + user.id, user: safeUser(user) });
  }

  const me = currentUser(req);
  if (u.pathname === '/api/auth/me') {
    if (!me) return send(res, 401, { message: 'Сессия недействительна' });
    return send(res, 200, safeUser(me));
  }
  if (!me) return send(res, 401, { message: 'Требуется вход в систему' });

  // Администратор: пользователи, роли, статистика.
  if (u.pathname.startsWith('/api/admin/users')) {
    if (!adminOnly(me, res)) return;
    const ps = u.pathname.split('/').filter(Boolean);
    if (req.method === 'GET') return send(res, 200, db.users.map(safeUser));
    if (req.method === 'PUT' && ps[3] && ps[4] === 'role') {
      const d = await body(req), x = db.users.find(z => z.id === Number(ps[3]));
      if (!x) return send(res, 404, { message: 'Пользователь не найден' });
      if (!['reader', 'librarian', 'admin'].includes(d.role)) return send(res, 422, { message: 'Неизвестная роль', errors: { role: 'Недопустимая роль' } });
      x.role = d.role; save(); return send(res, 200, safeUser(x));
    }
  }
  if (u.pathname === '/api/admin/stats' && req.method === 'GET') {
    if (!adminOnly(me, res)) return;
    const activeLoans = db.loans.filter(x => !x.returnedAt).length;
    return send(res, 200, {
      users: db.users.length,
      readers: db.readers.filter(x => !x.deletedAt).length,
      books: db.books.filter(x => !x.deletedAt).length,
      activeLoans,
      deleted: db.books.filter(x => x.deletedAt).length + db.authors.filter(x => x.deletedAt).length + db.genres.filter(x => x.deletedAt).length + db.publishers.filter(x => x.deletedAt).length + db.readers.filter(x => x.deletedAt).length,
    });
  }

  const delay = Number(u.searchParams.get('__delay') || 0);
  if (delay) await new Promise(r => setTimeout(r, delay));
  if (u.searchParams.get('__fail') === '500') return send(res, 500, { message: 'Принудительная ошибка сервера' });

  const parts = u.pathname.slice(5).split('/').filter(Boolean);
  const resource = parts[0], id = parts[1] && /^\d+$/.test(parts[1]) ? Number(parts[1]) : null, action = parts[2];

  // Выдачи.
  if (resource === 'loans') {
    if (req.method === 'GET') {
      let out = [...db.loans];
      if (me.role === 'reader') out = out.filter(x => x.reader.id === me.readerId);
      else if (me.role !== 'librarian') return send(res, 403, { message: 'Просмотр всех выдач доступен библиотекарю' });
      return send(res, 200, { items: out, page: 1, size: 100, total: out.length, totalPages: 1 });
    }
    if (req.method === 'POST' && !id) {
      if (!librarianOnly(me, res)) return;
      const d = await body(req);
      const book = db.books.find(x => x.id === Number(d.bookId) && !x.deletedAt);
      const reader = db.readers.find(x => x.id === Number(d.readerId) && !x.deletedAt);
      if (!book) return send(res, 404, { message: 'Книга не найдена' });
      if (!reader) return send(res, 404, { message: 'Читатель не найден' });
      if (book.copiesAvailable <= 0) return send(res, 409, { message: 'Нет свободных экземпляров книги' });
      book.copiesAvailable--;
      const loan = { id: nextId(db.loans), reader: { id: reader.id, fullName: reader.fullName }, book: { id: book.id, title: book.title }, issuedAt: now(), dueAt: new Date(Date.now() + (Number(d.days) || 14) * 86400000).toISOString(), returnedAt: null, status: 'active' };
      db.loans.push(loan); save(); return send(res, 201, loan);
    }
    if (req.method === 'POST' && id && action === 'return') {
      if (!librarianOnly(me, res)) return;
      const loan = db.loans.find(x => x.id === id);
      if (!loan) return send(res, 404, { message: 'Выдача не найдена' });
      if (!loan.returnedAt) {
        loan.returnedAt = now(); loan.status = 'returned';
        const b = db.books.find(x => x.id === loan.book.id); if (b) b.copiesAvailable++;
        save();
      }
      return send(res, 200, loan);
    }
    if (req.method === 'POST' && id && action === 'renew') {
      if (me.role !== 'reader') return send(res, 403, { message: 'Продление своей выдачи доступно читателю' });
      const loan = db.loans.find(x => x.id === id && x.reader.id === me.readerId);
      if (!loan) return send(res, 404, { message: 'Выдача не найдена' });
      if (loan.returnedAt) return send(res, 409, { message: 'Нельзя продлить уже закрытую выдачу' });
      loan.dueAt = new Date(new Date(loan.dueAt).getTime() + 14 * 86400000).toISOString(); save();
      return send(res, 200, loan);
    }
    return send(res, 405, { message: 'Метод не поддерживается' });
  }

  const sets = { authors: db.authors, genres: db.genres, publishers: db.publishers, readers: db.readers, books: db.books };
  const arr = sets[resource];
  if (!arr) return send(res, 404, { message: 'Ресурс не найден' });

  // Администратор может только смотреть каталог, а восстановление/физическое удаление делает в своём разделе.
  const wantsHard = req.method === 'DELETE' && u.searchParams.get('hard') === 'true';
  const wantsRestore = req.method === 'POST' && id && action === 'restore';
  if (wantsHard || wantsRestore) {
    if (!adminOnly(me, res)) return;
  } else if (req.method !== 'GET') {
    if (!librarianOnly(me, res)) return;
  }

  if (req.method === 'GET' && !id) {
    let out = [...arr];
    const includeDeleted = u.searchParams.get('includeDeleted') === 'true';
    if (includeDeleted && me.role !== 'admin') return send(res, 403, { message: 'Удалённые записи доступны только администратору' });
    if (!includeDeleted) out = out.filter(x => !x.deletedAt);
    if (resource === 'books') {
      const q = (u.searchParams.get('search') || '').toLowerCase();
      if (q) out = out.filter(x => x.title.toLowerCase().includes(q) || x.isbn.toLowerCase().includes(q));
      for (const k of ['genreId', 'publisherId', 'authorId']) {
        const v = Number(u.searchParams.get(k));
        if (v) out = out.filter(x => k === 'genreId' ? x.genreIds.includes(v) : k === 'authorId' ? x.authorIds.includes(v) : x.publisherId === v);
      }
    }
    const page = Number(u.searchParams.get('page') || 1), size = Number(u.searchParams.get('size') || 10), total = out.length;
    return send(res, 200, { items: out.slice((page - 1) * size, page * size).map(x => publicItem(resource, x)), page, size, total, totalPages: Math.max(1, Math.ceil(total / size)) });
  }
  if (req.method === 'GET' && id) {
    const x = arr.find(x => x.id === id && !x.deletedAt);
    return x ? send(res, 200, publicItem(resource, x)) : send(res, 404, { message: 'Запись не найдена' });
  }
  if (req.method === 'POST' && parts[1] === 'bulk-delete') {
    const d = await body(req); let n = 0;
    for (const x of arr) if ((d.ids || []).includes(x.id) && !x.deletedAt) { x.deletedAt = now(); n++; }
    save(); return send(res, 200, { deleted: n });
  }
  if (wantsRestore) {
    const x = arr.find(x => x.id === id); if (!x) return send(res, 404, { message: 'Запись не найдена' });
    x.deletedAt = null; save(); return send(res, 200, publicItem(resource, x));
  }
  if (req.method === 'POST' && !id) {
    const d = await body(req);
    if (resource === 'books' && db.books.some(x => x.isbn === d.isbn)) return send(res, 422, { message: 'Ошибка валидации', errors: { isbn: 'Книга с таким ISBN уже существует' } });
    if (resource === 'readers' && db.readers.some(x => x.email === d.email)) return send(res, 422, { message: 'Ошибка валидации', errors: { email: 'Читатель с таким email уже существует' } });
    const x = { ...d, id: nextId(arr), deletedAt: null };
    if (resource === 'books') { x.copiesAvailable = x.copiesTotal; x.createdAt = now(); }
    if (resource === 'readers' && x.card) x.card = { ...x.card, id: x.card.id || x.id };
    arr.push(x); save(); return send(res, 201, publicItem(resource, x));
  }
  if (req.method === 'PUT' && id) {
    const x = arr.find(x => x.id === id); if (!x) return send(res, 404, { message: 'Запись не найдена' });
    const d = await body(req);
    if (resource === 'books' && db.books.some(y => y.id !== id && y.isbn === d.isbn)) return send(res, 422, { message: 'Ошибка валидации', errors: { isbn: 'Книга с таким ISBN уже существует' } });
    Object.assign(x, d, { id }); if (resource === 'books') x.copiesAvailable = Math.min(x.copiesAvailable, x.copiesTotal);
    save(); return send(res, 200, publicItem(resource, x));
  }
  if (req.method === 'DELETE' && id) {
    const x = arr.find(x => x.id === id); if (!x) return send(res, 404, { message: 'Запись не найдена' });
    if (resource === 'publishers' && db.books.some(b => b.publisherId === id && !b.deletedAt)) return send(res, 409, { message: `Нельзя удалить издательство: связанных книг ${db.books.filter(b => b.publisherId === id && !b.deletedAt).length}` });
    if (wantsHard) { arr.splice(arr.indexOf(x), 1); save(); return send(res, 204); }
    x.deletedAt = now(); save(); return send(res, 204);
  }
  return send(res, 405, { message: 'Метод не поддерживается' });
}

http.createServer((req, res) => main(req, res).catch(e => { console.error(e); send(res, 500, { message: 'Внутренняя ошибка сервера' }); })).listen(port, () => console.log(`Mock API: http://localhost:${port}/api  CORS origin: ${origin}`));
