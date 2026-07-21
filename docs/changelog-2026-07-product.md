
        <div class="feature-card rounded-xl p-6">
          <div class="flex items-start gap-4">
            <div class="w-12 h-12 rounded-lg bg-violet-500/10 flex items-center justify-center flex-shrink-0">
              <span class="text-2xl">⇄</span>
            </div>
            <div>
              <h3 class="text-xl font-semibold text-white mb-2">Join presence filters</h3>
              <p class="text-white/40 leading-relaxed">List and count accept <code>has_link</code> / <code>missing_link</code> (e.g. Inbox = missing archive tag). Agents model tags without denormalized folder fields. Also <code>~=</code> substring contains in <code>where</code>.</p>
            </div>
          </div>
        </div>

        <div class="feature-card rounded-xl p-6">
          <div class="flex items-start gap-4">
            <div class="w-12 h-12 rounded-lg bg-emerald-500/10 flex items-center justify-center flex-shrink-0">
              <span class="text-2xl">◆</span>
            </div>
            <div>
              <h3 class="text-xl font-semibold text-white mb-2">Full cli-specs alignment</h3>
              <p class="text-white/40 leading-relaxed">poche now conforms to all four <a class="text-emerald-400" href="https://cli-specs.intrane.fr/">cli-specs</a>: structured <code>guide</code> + <code>/llms.txt</code>, richer <code>help-json</code>, dual-write <code>feedback</code> with admin-gated reads, and content-hash <code>update</code> (verify → smoke → atomic swap + stderr nudge).</p>
            </div>
          </div>
        </div>

        <div class="feature-card rounded-xl p-6">
          <div class="flex items-start gap-4">
            <div class="w-12 h-12 rounded-lg bg-sky-500/10 flex items-center justify-center flex-shrink-0">
              <span class="text-2xl">◉</span>
            </div>
            <div>
              <h3 class="text-xl font-semibold text-white mb-2">Self-update you can trust</h3>
              <p class="text-white/40 leading-relaxed">Versions are <code>sha256[:12]</code> of the binary. <code>poche update</code> downloads, verifies the hash, runs <code>version</code> as a smoke test, then swaps with a <code>.bak</code> rollback. <code>install.sh</code> writes the same VERSION file agents rely on.</p>
            </div>
          </div>
        </div>

        <div class="feature-card rounded-xl p-6">
          <div class="flex items-start gap-4">
            <div class="w-12 h-12 rounded-lg bg-amber-500/10 flex items-center justify-center flex-shrink-0">
              <span class="text-2xl">▣</span>
            </div>
            <div>
              <h3 class="text-xl font-semibold text-white mb-2">Dogfood backends + CMS hardening</h3>
              <p class="text-white/40 leading-relaxed">Three compiled example backends (social, marketplace, car renting), plus earlier v0.2 fixes: file blob unlink + RBAC, count API, range indexes, CORS preflight, and POST 201.</p>
            </div>
          </div>
        </div>
