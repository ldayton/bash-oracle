/* dump_ast.c - Dump command AST as s-expressions */

#include "config.h"
#include <stdio.h>
#include "bashtypes.h"
#include "command.h"
#include "y.tab.h"

void dump_command(COMMAND *cmd);

static void print_escaped(const char *s)
{
    if (!s) { printf("\"\""); return; }
    putchar('"');
    for (; *s; s++) {
        switch (*s) {
        case '"':  printf("\\\""); break;
        case '\\': printf("\\\\"); break;
        case '\n': printf("\\n"); break;
        case '\t': printf("\\t"); break;
        default:   putchar(*s); break;
        }
    }
    putchar('"');
}

static void dump_word(WORD_DESC *word)
{
    printf("(word ");
    print_escaped(word ? word->word : NULL);
    printf(")");
}

static void dump_word_list(WORD_LIST *list)
{
    for (WORD_LIST *w = list; w; w = w->next) {
        printf(" ");
        dump_word(w->word);
    }
}

static const char *connector_name(int c)
{
    switch (c) {
    case '&':     return "background";
    case '|':     return "pipe";
    case BAR_AND: return "pipe-stderr";
    case AND_AND: return "and";
    case OR_OR:   return "or";
    case ';':     return "semi";
    case '\n':    return "newline";
    default:      return "unknown";
    }
}

static const char *redir_name(int instruction)
{
    switch (instruction) {
    case r_output_direction:       return ">";
    case r_input_direction:        return "<";
    case r_inputa_direction:       return "<";
    case r_appending_to:           return ">>";
    case r_reading_until:          return "<<";
    case r_reading_string:         return "<<<";
    case r_duplicating_input:      return "<&";
    case r_duplicating_output:     return ">&";
    case r_duplicating_input_word: return "<&";
    case r_duplicating_output_word: return ">&";
    case r_deblank_reading_until:  return "<<-";
    case r_close_this:             return ">&-";
    case r_err_and_out:            return "&>";
    case r_input_output:           return "<>";
    case r_output_force:           return ">|";
    case r_append_err_and_out:     return "&>>";
    case r_move_input:             return "<&";
    case r_move_output:            return ">&";
    case r_move_input_word:        return "<&";
    case r_move_output_word:       return ">&";
    default:                       return "?";
    }
}

static int redirect_takes_filename(int ri)
{
    switch (ri) {
    case r_duplicating_input:
    case r_duplicating_output:
    case r_move_input:
    case r_move_output:
    case r_close_this:
        return 0;  /* dest is an fd number */
    default:
        return 1;  /* dest is a filename */
    }
}

static void dump_redirect(REDIRECT *r)
{
    printf("(redirect \"%s\"", redir_name(r->instruction));
    if (redirect_takes_filename(r->instruction)) {
        if (r->redirectee.filename)
            printf(" \"%s\"", r->redirectee.filename->word);
    } else {
        printf(" %d", r->redirectee.dest);
    }
    printf(")");
}

static void dump_redirects(REDIRECT *r)
{
    for (; r; r = r->next) {
        printf(" ");
        dump_redirect(r);
    }
}

static void dump_simple(SIMPLE_COM *cmd)
{
    printf("(command");
    dump_word_list(cmd->words);
    dump_redirects(cmd->redirects);
    printf(")");
}

static void dump_for(FOR_COM *cmd)
{
    printf("(for ");
    dump_word(cmd->name);
    printf(" (in");
    dump_word_list(cmd->map_list);
    printf(") ");
    dump_command(cmd->action);
    printf(")");
}

#if defined(ARITH_FOR_COMMAND)
static void dump_arith_for(ARITH_FOR_COM *cmd)
{
    printf("(arith-for (init");
    dump_word_list(cmd->init);
    printf(") (test");
    dump_word_list(cmd->test);
    printf(") (step");
    dump_word_list(cmd->step);
    printf(") ");
    dump_command(cmd->action);
    printf(")");
}
#endif

static void dump_case(CASE_COM *cmd)
{
    printf("(case ");
    dump_word(cmd->word);
    for (PATTERN_LIST *p = cmd->clauses; p; p = p->next) {
        printf(" (pattern (");
        for (WORD_LIST *w = p->patterns; w; w = w->next) {
            dump_word(w->word);
            if (w->next) printf(" ");
        }
        printf(") ");
        dump_command(p->action);
        printf(")");
    }
    printf(")");
}

static void dump_while(WHILE_COM *cmd, const char *kw)
{
    printf("(%s ", kw);
    dump_command(cmd->test);
    printf(" ");
    dump_command(cmd->action);
    printf(")");
}

static void dump_if(IF_COM *cmd)
{
    printf("(if ");
    dump_command(cmd->test);
    printf(" ");
    dump_command(cmd->true_case);
    if (cmd->false_case) {
        printf(" ");
        dump_command(cmd->false_case);
    }
    printf(")");
}

#if defined(SELECT_COMMAND)
static void dump_select(SELECT_COM *cmd)
{
    printf("(select ");
    dump_word(cmd->name);
    printf(" (in");
    dump_word_list(cmd->map_list);
    printf(") ");
    dump_command(cmd->action);
    printf(")");
}
#endif

#if defined(DPAREN_ARITHMETIC)
static void dump_arith(ARITH_COM *cmd)
{
    printf("(arith");
    dump_word_list(cmd->exp);
    printf(")");
}
#endif

#if defined(COND_COMMAND)
static void dump_cond(COND_COM *cmd)
{
    switch (cmd->type) {
    case COND_AND:
        printf("(cond-and ");
        dump_cond(cmd->left);
        printf(" ");
        dump_cond(cmd->right);
        printf(")");
        break;
    case COND_OR:
        printf("(cond-or ");
        dump_cond(cmd->left);
        printf(" ");
        dump_cond(cmd->right);
        printf(")");
        break;
    case COND_UNARY:
        printf("(cond-unary \"%s\" ", cmd->op->word);
        dump_cond(cmd->left);
        printf(")");
        break;
    case COND_BINARY:
        printf("(cond-binary \"%s\" ", cmd->op->word);
        dump_cond(cmd->left);
        printf(" ");
        dump_cond(cmd->right);
        printf(")");
        break;
    case COND_TERM:
        printf("(cond-term \"%s\")", cmd->op->word);
        break;
    case COND_EXPR:
        printf("(cond-expr ");
        dump_cond(cmd->left);
        printf(")");
        break;
    }
}
#endif

void dump_command(COMMAND *cmd)
{
    if (!cmd) { printf("()"); return; }

    int need_close_neg = 0, need_close_time = 0;
    if (cmd->flags & CMD_INVERT_RETURN) {
        printf("(negation ");
        need_close_neg = 1;
    }
    if (cmd->flags & CMD_TIME_PIPELINE) {
        printf("(time%s ", (cmd->flags & CMD_TIME_POSIX) ? " -p" : "");
        need_close_time = 1;
    }

    switch (cmd->type) {
    case cm_simple:
        dump_simple(cmd->value.Simple);
        break;
    case cm_for:
        dump_for(cmd->value.For);
        break;
#if defined(ARITH_FOR_COMMAND)
    case cm_arith_for:
        dump_arith_for(cmd->value.ArithFor);
        break;
#endif
    case cm_case:
        dump_case(cmd->value.Case);
        break;
    case cm_while:
        dump_while(cmd->value.While, "while");
        break;
    case cm_until:
        dump_while(cmd->value.While, "until");
        break;
    case cm_if:
        dump_if(cmd->value.If);
        break;
#if defined(SELECT_COMMAND)
    case cm_select:
        dump_select(cmd->value.Select);
        break;
#endif
#if defined(DPAREN_ARITHMETIC)
    case cm_arith:
        dump_arith(cmd->value.Arith);
        break;
#endif
#if defined(COND_COMMAND)
    case cm_cond:
        printf("(cond ");
        dump_cond(cmd->value.Cond);
        printf(")");
        break;
#endif
    case cm_group:
        printf("(brace-group ");
        dump_command(cmd->value.Group->command);
        printf(")");
        break;
    case cm_subshell:
        printf("(subshell ");
        dump_command(cmd->value.Subshell->command);
        printf(")");
        break;
    case cm_function_def:
        printf("(function \"%s\" ", cmd->value.Function_def->name->word);
        dump_command(cmd->value.Function_def->command);
        printf(")");
        break;
    case cm_coproc:
        printf("(coproc");
        if (cmd->value.Coproc->name)
            printf(" \"%s\"", cmd->value.Coproc->name);
        printf(" ");
        dump_command(cmd->value.Coproc->command);
        printf(")");
        break;
    case cm_connection:
        printf("(%s ", connector_name(cmd->value.Connection->connector));
        dump_command(cmd->value.Connection->first);
        if (cmd->value.Connection->second) {
            printf(" ");
            dump_command(cmd->value.Connection->second);
        }
        printf(")");
        break;
    default:
        printf("(unknown %d)", cmd->type);
        break;
    }

    if (cmd->redirects && cmd->type != cm_simple)
        dump_redirects(cmd->redirects);

    if (need_close_time) printf(")");
    if (need_close_neg) printf(")");
}
