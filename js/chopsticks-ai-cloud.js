
(function (global) {
  'use strict';

  var API = '/api/chopsticks-ai';
  var CFG_URL = '/chopsticks-ai/supabase-public.json';
  var SESSION_KEY = 'chq.ai.auth';
  var cfg = null;
  var session = null;
  var listeners = [];

  function emit() {
    listeners.forEach(function (fn) {
      try { fn(session); } catch (e) {}
    });
  }

  function storage() {
    try {
      return global.sessionStorage;
    } catch (e) {
      return null;
    }
  }

  function loadLocalSession() {
    try {
      var store = storage();
      if (!store) return null;
      var raw = store.getItem(SESSION_KEY);
      if (!raw) return null;
      var s = JSON.parse(raw);
      if (!s || !s.access_token || !s.user || !s.user.id) return null;
      return s;
    } catch (e) { return null; }
  }

  function saveLocalSession(s) {
    try {
      var store = storage();
      if (!store) return;
      if (s && s.access_token && s.user && s.user.id) {
        store.setItem(SESSION_KEY, JSON.stringify(s));
      } else {
        store.removeItem(SESSION_KEY);
      }
    } catch (e) {}
  }

  function clearStoredSession() {
    session = null;
    saveLocalSession(null);
    try { global.localStorage.removeItem(SESSION_KEY); } catch (e) {}
  }

  function wrapSecret() {
    return ['chq', 'sb', '26', 'v1'].join('.') + '|chopstickshq.com';
  }

  async function decryptAnon(encB64, ivB64) {
    var enc = Uint8Array.from(atob(encB64), function (c) { return c.charCodeAt(0); });
    var iv = Uint8Array.from(atob(ivB64), function (c) { return c.charCodeAt(0); });
    var hash = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(wrapSecret()));
    var key = await crypto.subtle.importKey('raw', hash, { name: 'AES-GCM' }, false, ['decrypt']);
    var pt = await crypto.subtle.decrypt({ name: 'AES-GCM', iv: iv }, key, enc);
    return new TextDecoder().decode(pt);
  }

  async function ensureConfig() {
    if (cfg && cfg.anonKey) return cfg;
    var res = await fetch(CFG_URL, { cache: 'no-store' });
    if (!res.ok) throw new Error('Cloud config unavailable');
    var raw = await res.json();
    if (!raw.url || !raw.anonEnc || !raw.anonIv) throw new Error('Cloud config incomplete');
    cfg = Object.assign({}, raw, { anonKey: await decryptAnon(raw.anonEnc, raw.anonIv) });
    delete cfg.anonEnc;
    delete cfg.anonIv;
    return cfg;
  }

  async function apiPost(body) {
    var headers = { 'Content-Type': 'application/json' };
    if (session && session.access_token) {
      headers.Authorization = 'Bearer ' + session.access_token;
    }
    var res = await fetch(API, {
      method: 'POST',
      headers: headers,
      body: JSON.stringify(body)
    });
    var text = await res.text();
    var out = null;
    try { out = text ? JSON.parse(text) : null; } catch (e) { out = text; }
    if (!res.ok) {
      var msg = (out && (out.error || out.message)) || ('HTTP ' + res.status);
      var err = new Error(typeof msg === 'string' ? msg : JSON.stringify(msg));
      err.status = res.status;
      err.body = out;
      throw err;
    }
    return out;
  }

  async function rest(path, init) {
    var c = await ensureConfig();
    init = init || {};
    if (!session || !session.access_token) {
      throw new Error('Not signed in');
    }
    var headers = Object.assign({
      apikey: c.anonKey,
      'Content-Type': 'application/json',
      Authorization: 'Bearer ' + session.access_token
    }, init.headers || {});
    var res = await fetch(c.url + '/rest/v1/' + path, Object.assign({}, init, { headers: headers }));
    var text = await res.text();
    var body = null;
    try { body = text ? JSON.parse(text) : null; } catch (e) { body = text; }
    if (!res.ok) {
      var msg = (body && (body.message || body.error || body.msg)) || ('HTTP ' + res.status);
      throw new Error(typeof msg === 'string' ? msg : JSON.stringify(msg));
    }
    return body;
  }

  async function validateSession() {
    if (!session || !session.access_token) {
      clearStoredSession();
      emit();
      return null;
    }
    try {
      var me = await apiPost({ action: 'authMe' });
      if (!me || !me.user || !me.user.id) {
        clearStoredSession();
        emit();
        return null;
      }
      session.user = me.user;
      session.modelPicker = !!me.modelPicker;
      session.appVersion = me.appVersion || null;
      saveLocalSession(session);
      return session;
    } catch (e) {
      clearStoredSession();
      emit();
      return null;
    }
  }

  async function refreshIfNeeded() {
    if (!session || !session.refresh_token) return session;
    var exp = session.expires_at ? session.expires_at * 1000 : 0;
    if (exp && Date.now() < exp - 60000) return validateSession();
    try {
      var body = await apiPost({
        action: 'authRefresh',
        refresh_token: session.refresh_token
      });
      session = normalizeSession(body);
      if (!session || !session.user || !session.user.id) {
        clearStoredSession();
        emit();
        return null;
      }
      saveLocalSession(session);
      emit();
      return validateSession();
    } catch (e) {
      clearStoredSession();
      emit();
      return null;
    }
  }

  function normalizeSession(body) {
    if (!body || !body.access_token || !body.user || !body.user.id) return null;
    return {
      access_token: body.access_token,
      refresh_token: body.refresh_token,
      expires_at: body.expires_at || (Math.floor(Date.now() / 1000) + (body.expires_in || 3600)),
      user: {
        id: body.user.id,
        email: body.user.email || null
      },
      modelPicker: !!body.modelPicker,
      appVersion: body.appVersion || null
    };
  }

  function verNewer(a, b) {
    function parts(v) {
      return String(v || '').replace(/^v/i, '').split(/[.-]/).map(function (x) { return parseInt(x, 10) || 0; });
    }
    var A = parts(a), B = parts(b);
    for (var i = 0; i < Math.max(A.length, B.length); i++) {
      var x = A[i] || 0, y = B[i] || 0;
      if (x !== y) return x > y;
    }
    return false;
  }

  var Cloud = {
    onChange: function (fn) {
      listeners.push(fn);
      return function () {
        listeners = listeners.filter(function (x) { return x !== fn; });
      };
    },
    getSession: function () { return session; },
    userEmail: function () {
      return (session && session.user && session.user.email) || '';
    },
    isSignedIn: function () {
      return Boolean(session && session.access_token && session.user && session.user.id);
    },
    canPickModel: function () {
      return Boolean(session && session.modelPicker);
    },
    getAppVersion: function () {
      var baked = '3.7.5b';
      var remote = (session && session.appVersion) || '';
      if (!remote) return baked;
      return verNewer(remote, baked) ? remote : baked;
    },

    init: async function () {
      await ensureConfig();
      try { global.localStorage.removeItem(SESSION_KEY); } catch (e) {}
      session = loadLocalSession();
      if (session) await refreshIfNeeded();
      else {
        clearStoredSession();
        emit();
      }
      return session;
    },

    sendSignupCode: async function (email, password) {
      return this.signUp(email, password);
    },

    verifySignup: async function (email, password) {
      return this.signUp(email, password);
    },

    signUp: async function (email, password) {
      clearStoredSession();
      emit();
      var body = await apiPost({
        action: 'authSignUp',
        email: email,
        password: password
      });
      if (body.access_token) {
        session = normalizeSession(body);
        if (!session) throw new Error('Sign up succeeded but session was invalid.');
        saveLocalSession(session);
        await validateSession();
        return { needsConfirm: false, session: session };
      }
      if (body.needsSignIn) {
        return { needsConfirm: true, message: body.message };
      }
      throw new Error(body.error || 'Could not create account.');
    },

    verifyLogin: async function (email, password) {
      return this.signIn(email, password);
    },

    signIn: async function (email, password) {
      clearStoredSession();
      emit();
      var body = await apiPost({ action: 'authSignIn', email: email, password: password });
      session = normalizeSession(body);
      if (!session) throw new Error(body.error || 'Sign in failed — invalid session.');
      saveLocalSession(session);
      await validateSession();
      return session;
    },

    signOut: async function () {
      clearStoredSession();
      emit();
    },

    listChats: async function () {
      await refreshIfNeeded();
      if (!Cloud.isSignedIn()) return [];
      var body = await apiPost({ action: 'chatsList' });
      return Array.isArray(body.chats) ? body.chats : [];
    },

    createChat: async function (opts) {
      await refreshIfNeeded();
      if (!Cloud.isSignedIn()) throw new Error('Not signed in');
      opts = opts || {};
      var body = await apiPost({
        action: 'chatCreate',
        title: opts.title || 'New Chat',
        client: opts.client || 'web',
        tier: opts.tier || null
      });
      return body.chat;
    },

    updateChat: async function (id, patch) {
      await refreshIfNeeded();
      if (!Cloud.isSignedIn()) throw new Error('Not signed in');
      patch = patch || {};
      await apiPost({
        action: 'chatPatch',
        chatId: id,
        title: patch.title,
        tier: patch.tier
      });
      return patch;
    },

    deleteChat: async function (id) {
      await refreshIfNeeded();
      if (!Cloud.isSignedIn()) throw new Error('Not signed in');
      await apiPost({ action: 'chatDelete', chatId: id });
    },

    loadMessages: async function (chatId) {
      await refreshIfNeeded();
      if (!Cloud.isSignedIn()) return [];
      var body = await apiPost({ action: 'chatMessages', chatId: chatId });
      return (Array.isArray(body.messages) ? body.messages : []).map(function (m) {
        var sources = Array.isArray(m.sources) ? m.sources : [];
        var extra = {};
        var visible = [];
        sources.forEach(function (s) {
          if (s && s.title === '\u200Bcsai' && s.snippet) {
            try { extra = JSON.parse(s.snippet) || {}; } catch (e) {}
          } else {
            visible.push(s);
          }
        });
        return {
          role: m.role,
          content: m.content,
          sources: visible,
          agents: extra.agents || null,
          conversation: extra.conversation || null,
          files: extra.files || null
        };
      });
    },

    saveMessages: async function (chatId, messages, meta) {
      await refreshIfNeeded();
      if (!Cloud.isSignedIn()) throw new Error('Not signed in');
      meta = meta || {};
      var rows = (messages || []).map(function (m) {
        var sources = (m.sources || []).slice();
        if (m.agents || m.conversation || m.files) {
          sources.push({
            title: '\u200Bcsai',
            snippet: JSON.stringify({
              agents: m.agents || null,
              conversation: m.conversation || null,
              files: m.files || null
            })
          });
        }
        return {
          role: m.role,
          content: m.content || m.text || '',
          sources: sources
        };
      });
      await apiPost({
        action: 'chatSave',
        chatId: chatId,
        title: meta.title,
        tier: meta.tier,
        messages: rows
      });
      return messages;
    },

    listModels: async function (keys) {
      keys = keys || {};
      var req = { action: 'listModels' };
      if (keys.groqKey) req.groqKey = keys.groqKey;
      if (keys.openRouterKey) req.openRouterKey = keys.openRouterKey;
      if (keys.anthropicKey) req.anthropicKey = keys.anthropicKey;
      var body = await apiPost(req);
      return body;
    },

    listOpenRouterModels: async function (groqKey) {
      await refreshIfNeeded();
      if (!Cloud.canPickModel()) throw new Error('Model picker not enabled');
      var req = { action: 'openRouterModels' };
      if (groqKey) req.groqKey = groqKey;
      var body = await apiPost(req);
      return Array.isArray(body.models) ? body.models : [];
    },

    MAX_ATTACH_BYTES: 500 * 1024 * 1024,
    ATTACH_BUCKET: 'cs-ai-attachments',

    uploadAttachment: async function (file, opts) {
      opts = opts || {};
      await refreshIfNeeded();
      if (!Cloud.isSignedIn()) {
        throw new Error('Sign in to upload files (up to 500 MB).');
      }
      if (!file || !file.size) throw new Error('Empty file');
      if (file.size > Cloud.MAX_ATTACH_BYTES) {
        throw new Error('Each file must be 500 MB or smaller.');
      }
      var c = await ensureConfig();
      var safeName = String(file.name || 'file').replace(/[^\w.\-()+ ]+/g, '_').slice(0, 180);
      var rnd = new Uint8Array(8);
      if (global.crypto && global.crypto.getRandomValues) global.crypto.getRandomValues(rnd);
      var hex = Array.prototype.map.call(rnd, function (b) { return ('0' + b.toString(16)).slice(-2); }).join('');
      var path = session.user.id + '/' + Date.now().toString(36) + '-' + hex + '-' + safeName;
      var mime = file.type || 'application/octet-stream';

      if (file.size > 5 * 1024 * 1024 && global.tus && global.tus.Upload) {
        await new Promise(function (resolve, reject) {
          var upload = new global.tus.Upload(file, {
            endpoint: c.url + '/storage/v1/upload/resumable',
            retryDelays: [0, 2000, 5000, 10000],
            headers: {
              authorization: 'Bearer ' + session.access_token,
              apikey: c.anonKey,
              'x-upsert': 'true'
            },
            uploadDataDuringCreation: true,
            removeFingerprintOnSuccess: true,
            metadata: {
              bucketName: Cloud.ATTACH_BUCKET,
              objectName: path,
              contentType: mime,
              cacheControl: '3600'
            },
            chunkSize: 6 * 1024 * 1024,
            onError: function (err) { reject(err); },
            onProgress: function (sent, total) {
              if (opts.onProgress && total) opts.onProgress(sent / total);
            },
            onSuccess: function () { resolve(); }
          });
          upload.start();
        });
      } else {
        var res = await fetch(
          c.url + '/storage/v1/object/' + Cloud.ATTACH_BUCKET + '/' + path.split('/').map(encodeURIComponent).join('/'),
          {
            method: 'POST',
            headers: {
              apikey: c.anonKey,
              Authorization: 'Bearer ' + session.access_token,
              'Content-Type': mime,
              'x-upsert': 'true'
            },
            body: file
          }
        );
        if (!res.ok) {
          var t = await res.text().catch(function () { return ''; });
          throw new Error(t || ('Upload failed (' + res.status + ')'));
        }
        if (opts.onProgress) opts.onProgress(1);
      }

      var signedUrl = await Cloud.createSignedUrl(path, 60 * 60 * 24);
      return { path: path, name: safeName, mime: mime, size: file.size, signedUrl: signedUrl };
    },

    createSignedUrl: async function (path, expiresSec) {
      await refreshIfNeeded();
      if (!Cloud.isSignedIn()) throw new Error('Not signed in');
      var c = await ensureConfig();
      var body = await fetch(
        c.url + '/storage/v1/object/sign/' + Cloud.ATTACH_BUCKET + '/' +
          path.split('/').map(encodeURIComponent).join('/'),
        {
          method: 'POST',
          headers: {
            apikey: c.anonKey,
            Authorization: 'Bearer ' + session.access_token,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({ expiresIn: expiresSec || 86400 })
        }
      ).then(function (r) { return r.json(); });
      if (!body || !body.signedURL) throw new Error('Could not sign attachment URL');
      var rel = body.signedURL;
      if (/^https?:/i.test(rel)) return rel;
      return c.url + '/storage/v1' + (rel.charAt(0) === '/' ? rel : '/' + rel);
    }
  };

  global.ChopsticksAICloud = Cloud;
})(typeof window !== 'undefined' ? window : globalThis);
