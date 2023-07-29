{ config, lib, pkgs, ... }: with lib; let
  cfg = config.services.maubot-github;
  maubot = pkgs.callPackage ../../../pkgs/maubot.nix { };

  maubotGitHubStandaloneCfg = {
    user = {
      credentials = {
        id = cfg.username;
        homeserver = cfg.homeserver;
      };
      sync = true;
      autojoin = true;
      displayname = "GitHub";
      avatar_url = "mxc://nevarro.space/KIxmjtSrrDDNVPBeYEACcUiR";
      ignore_initial_sync = true;
      ignore_first_sync = true;
    };
    server = {
      hostname = "0.0.0.0";
      port = "29316";
      base_path = "/_matrix/maubot/plugin/github";
      public_url = cfg.publicUrl;
    };
    database = "sqlite://${cfg.dataDir}/github.db";
    logging = {
      version = 1;
      formatters.journal_fmt.format = "%(name)s: %(message)s";
      handlers.journal = {
        class = "systemd.journal.JournalHandler";
        formatter = "journal_fmt";
      };
      loggers = {
        maubot.level = "DEBUG";
        mau.level = "DEBUG";
        aiohttp.level = "INFO";
      };
      root = {
        level = "DEBUG";
        handlers = [ "journal" ];
      };
    };

    plugin_config = {
      reset_tokens = false;
      command_options.prefix = [ "github" "gh" ];
      message_options = {
        msgtype = "m.notice";
        aggregation_timeout = 1;
      };
      templates = {
        repo_prefix = "<strong>[{{ repo_link(repository) }}]</strong>";
        repo_sender_prefix = "{{ templates.repo_prefix }} {{ user_link(sender) }}";
        issue_link = "{{ issueish_link(issue) }}";
        pr_link = "{{ issueish_link(pull_request, pull_request=True) }}";
        label_aggregation = ''
          {% if aggregation.added_labels %}
              added {{ util.join_human_list(aggregation.added_labels, mutate=fancy_label) }}
              {% if not aggregation.removed_labels %} to{% endif %}
          {% endif %}
          {% if aggregation.removed_labels %}
              {% if aggregation.added_labels %}
                  and
              {% endif %}
              removed {{ util.join_human_list(aggregation.removed_labels, mutate=fancy_label) }} from
          {% endif %}
        '';
      };
      macros = ''
        {%- macro fancy_label(label) -%}
            <font
                data-mx-color="#{{ util.contrast_fg(label.color) }}"
                data-mx-bg-color="#{{ label.color }}"
                title="{{ label.description }}"
            >&nbsp;{{ label.name }}&nbsp;</font>
        {%- endmacro -%}

        {%- macro fancy_labels(labels) -%}
            {% for label in labels %}
                {{ fancy_label(label) }}
            {% endfor %}
        {%- endmacro -%}

        {%- macro pluralize(value) -%}
            {% if value != 1 %}s{% endif %}
        {%- endmacro -%}

        {%- macro issueish_link(issue, pull_request=False) -%}
            <a href="{{ issue.html_url }}">
                {{"pull request" if pull_request or issue.pull_request else "issue"}}
                #{{ issue.number -}}
            </a>: {{ issue.title|e }}
        {%- endmacro -%}

        {%- macro user_link(user) -%}
            <a data-mautrix-exclude-plaintext href="{{ user.html_url }}">{{ (user.name or user.login)|e }}</a>
        {%- endmacro -%}

        {%- macro commit_user_link(user) -%}
            {% if user.username %}
                <a data-mautrix-exclude-plaintext href="https://github.com/{{ user.username }}">{{ user.name|e }}</a>
            {% else %}
                {{ user.name|e }}
            {% endif %}
        {%- endmacro -%}

        {%- macro milestone_link(milestone, text=True) -%}
            {% if text %}milestone {% endif %}<a href="{{ milestone.html_url }}">{{ milestone.title|e }}</a>
        {%- endmacro -%}

        {%- macro repo_link(repo, important=True) -%}
            <a data-mautrix-exclude-plaintext href="{{ repo.html_url }}">{{ repo.full_name|e }}</a>
        {%- endmacro -%}

        {%- macro personal_link(user, self_text=None, possessive=False, self=sender) -%}
            {% if user.id == self.id %}
                {% if self_text %}
                    {{ self_text }}
                {% elif possessive %}
                    their
                {% else %}
                    themselves
                {% endif %}
            {% else %}
                {{ user_link(user) }}
                {%- if possessive %}'s{% endif %}
            {% endif %}
        {%- endmacro -%}
      '';
      messages = {
        ping = "";
        create = "";
        star = "{{ templates.repo_sender_prefix }} {% if action == DELETED %}un{% endif %}starred the repo";
        fork = "{{ templates.repo_prefix }} Repo forked into {{ repo_link(forkee) }}";
        issues = ''
          {{ templates.repo_sender_prefix }}
          {% if action == OPENED %}
              opened {{ templates.issue_link }}<br/>
              {% if issue.body %}
                  <blockquote>{{ issue.body|markdown }}</blockquote>
              {% endif %}
              {{ fancy_labels(issue.labels) }}
          {% elif action == LABELED %}           {% do abort() %}
          {% elif action == UNLABELED %}         {% do abort() %}
          {% elif action == X_LABEL_AGGREGATE %} {{ templates.label_aggregation }}
          {% elif action == MILESTONED %}        added {{ templates.issue_link }} to {{ milestone_link(milestone) }}
          {% elif action == DEMILESTONED %}      removed {{ templates.issue_link }} from {{ milestone_link(milestone) }}
          {% elif action == X_MILESTONE_CHANGED %} moved {{ templates.issue_link }} from {{ milestone_link(aggregation.from) }} to {{ milestone_link(aggregation.to, text=False) }}
          {% elif action == ASSIGNED %}          assigned {{ user_link(assignee) }} to
          {% elif action == UNASSIGNED %}        unassigned {{ user_link(assignee) }} from
          {% else %}                             {{ action }}
          {% endif %}
          {% if action not in (OPENED, MILESTONED, DEMILESTONED, X_MILESTONE_CHANGED) %}
              {{ templates.issue_link }}
          {% endif %}
        '';
        pull_request = ''
          {{ templates.repo_sender_prefix }}
          {% if action == OPENED %}
              {% if pull_request.draft %}drafted
              {% else %}opened{% endif %}
              {{ templates.pr_link }}<br/>
              {% if pull_request.body %}
                  <blockquote>{{ pull_request.body|markdown }}</blockquote>
              {% endif %}
              {{ fancy_labels(pull_request.labels) }}
          {% elif action == CLOSED %}
            {% if pull_request.merged_at %}
              <a data-mautrix-exclude-plaintext href="{{ repository.html_url }}/commit/{{ pull_request.merge_commit_sha }}">merged</a>
            {% else %}
              closed
            {% endif %}
          {% elif action == SYNCHRONIZE and pull_request.head.repo.id == pull_request.base.repo.id %} {% do abort() %}
          {% elif action == SYNCHRONIZE %}pushed something to
          {% elif action == LABELED %}           {% do abort() %}
          {% elif action == UNLABELED %}         {% do abort() %}
          {% elif action == X_LABEL_AGGREGATE %} {{ templates.label_aggregation }}
          {% elif action == MILESTONED %}        added {{ templates.pr_link }} to {{ milestone_link(milestone) }}
          {% elif action == DEMILESTONED %}      removed {{ templates.pr_link }} from {{ milestone_link(milestone) }}
          {% elif action == X_MILESTONE_CHANGED %} moved {{ templates.pr_link }} from {{ milestone_link(aggregation.from) }} to {{ milestone_link(aggregation.to, text=False) }}
          {% elif action == ASSIGNED %}          assigned {{ personal_link(requested_reviewer) }} to
          {% elif action == UNASSIGNED %}        unassigned {{ personal_link(requested_reviewer) }} from
          {% elif action == REVIEW_REQUESTED %}
          {% if requested_reviewer.id == sender.id %}
                  self-requested a review for
              {% else %}
                  requested a review from {{ user_link(requested_reviewer) }} for
              {% endif %}
          {% elif action == REVIEW_REQUEST_REMOVED %}
              removed {{ personal_link(requested_reviewer, possessive=True) }} request for review from
          {% elif action == READY_FOR_REVIEW %}    marked {{ templates.pr_link }} as ready for review
          {% else %}                             {{ action }}
          {% endif %}
          {% if action not in (OPENED, MILESTONED, DEMILESTONED, X_MILESTONE_CHANGED, READY_FOR_REVIEW) %}
              {{ templates.pr_link }}
          {% endif %}
        '';
        pull_request_review = ''
          {{ templates.repo_sender_prefix }}
          {% if action == SUBMITTED %}
              <a href="{{ review.html_url }}">{{ review.state.action_str }}</a>
              {{ templates.pr_link }}
              {%- if review.body %}
                  : <blockquote>{{ review.body|markdown }}</blockquote>
              {% endif %}
          {% else %}
              {% do abort() %}
          {% endif %}
        '';
        pull_request_review_comment = "{% do abort() %}";
        issue_comment = ''
          {{ templates.repo_sender_prefix }}
          {% if action == CREATED %}
              {% if aggregation.closed %}
                  closed and
              {% elif aggregation.reopened %}
                  reopened and
              {% endif %}
              <a href="{{ comment.html_url }}">commented</a> on {{ templates.issue_link }}:
              <blockquote>{{ comment.body|markdown }}</blockquote>
          {% else %}
              {{ action }}
              {{ personal_link(comment.user, possessive=True) }}
              <a href="{{ comment.html_url }}">comment</a> on {{ templates.issue_link }}
          {% endif %}
        '';
        push = ''
          {{ templates.repo_sender_prefix }}
          {% if forced %}force{% endif %}
          {% if deleted %}deleted {{ util.ref_type(ref) }}
          {% else %}
              pushed
              {% if size == distinct_size %}
                  <a href="{{ compare }}">{{ size }} commit{{ pluralize(size) }}</a>
              {% else %}
                  <a href="{{ compare }}">{{ distinct_size }} new commit{{ pluralize(distinct_size) }}</a>
                  (and {{ size - distinct_size }} existing commits)
              {% endif %}
              to
          {% endif %}
          {{ util.ref_name(ref) }}
          {%- if created %} (new {{ util.ref_type(ref) }}){% endif -%}
          {%- if commits|length > 0 %}:{% endif -%}
          <ul>
          {% for commit in commits %}
              {% if commit.distinct %}
                  <li>
                      <code><a href="{{ commit.url }}">{{ commit.id[:8] }}</a></code>
                      {{ util.cut_message(commit.message)|e }}
                      {% if commit.author.username != sender.login %}
                          by {{ commit_user_link(commit.author) }}
                      {% endif %}
                  </li>
              {% endif %}
          {% endfor %}
          </ul>
        '';
        release = ''
          {% if action != PUBLISHED %} {% do abort() %} {% endif %}

          {{ templates.repo_sender_prefix }} published
          <a href="{{ release.html_url }}">{{ release.tag_name }}: {{ release.name }}</a>
        '';
        meta = ''
          {% if action != DELETED %} {% do abort() %} {% endif %}

          {{ templates.repo_prefix }} Webhook deleted by {{ user_link(sender) }}
        '';
        gollum = ''
          {% if pages|length == 0 %}
              {% do abort() %}
          {% endif %}

          {% macro page_link(page) %}
              <a data-mautrix-exclude-plaintext href="{{ page.html_url }}">{{ page.title }}</a>
              (<a href="{{ page.html_url }}/_compare/{{ page.sha }}^...{{ page.sha }}">diff</a>)
          {% endmacro %}

          {% set created, edited = [], [] %}
          {% for page in pages %}
              {% if page.action == CREATED %}
                  {% do created.append(page_link(page)) %}
              {% elif page.action == EDITED %}
                  {% do edited.append(page_link(page)) %}
              {% endif %}
          {% endfor %}

          {{ templates.repo_sender_prefix }}
          {% if created %}
              created {{ util.join_human_list(created) }}
          {% endif %}
          {% if edited %}
              {% if created %}
                  and
              {% endif %}
              edited {{ util.join_human_list(edited) }}
          {% endif %}
          on the wiki
        '';
        repository = ''
          {{ templates.repo_sender_prefix }}
          {% if action == PUBLICIZED %}   made the repo public
          {% elif action == PRIVATIZED %} made the repo private
          {% elif action == TRANSFERRED %}
              {% set source = changes.owner.from.organization or changes.owner.from.user %}
              transferred the repo from <a href="https://github.com/{{ source.login }}">{{ source.login }}</a>
          {% elif action == RENAMED %}    renamed the repo from {{ changes.repository.name.from }} to {{ repository.name }}
          {% else %}                      {{action}} the repo
          {% endif %}
        '';
      };
    };
  };
  format = pkgs.formats.yaml { };
  configYaml = format.generate "config.yaml" maubotGitHubStandaloneCfg;
in
{
  options = {
    services.maubot-github = {
      enable = mkEnableOption "GitHub maubot";
      username = mkOption { type = types.str; };
      homeserver = mkOption { type = types.str; };
      publicUrl = mkOption { type = types.str; };
      secretYAML = mkOption { type = types.path; };
      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/maubot-github";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.maubot-github = {
      description = "GitHub Maubot";
      after = [
        "matrix-synapse.target"
        "github_maubot_secrets_yaml-key.service"
      ];
      wantedBy = [ "multi-user.target" ];
      preStart = ''
        ${pkgs.git}/bin/git clone https://github.com/maubot/github src
        cp -r src/* .
        rm -rf src
        ${pkgs.yq-go}/bin/yq ea '. as $item ireduce ({}; . * $item )' \
          ${configYaml} ${cfg.secretYAML} > config.yaml
      '';
      serviceConfig = {
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${maubot}/bin/standalone";
        Restart = "on-failure";
        User = "maubot-github";
        Group = "maubot-github";
        SupplementaryGroups = [ "keys" ];
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts = {
        "matrix.nevarro.space" = {
          enableACME = true;
          forceSSL = true;
          locations."/_matrix/maubot/plugin/github" = {
            proxyPass = "http://0.0.0.0:29316"; # without a trailing /
            extraConfig = ''
              access_log /var/log/nginx/maubot-github.access.log;
            '';
          };
        };
      };
    };

    users = {
      users.maubot-github = {
        group = "maubot-github";
        isSystemUser = true;
        home = cfg.dataDir;
        createHome = true;
      };
      groups.maubot-github = { };
    };

    # Add a backup service.
    services.backup.backups.maubot-github = {
      path = cfg.dataDir;
    };
  };
}
