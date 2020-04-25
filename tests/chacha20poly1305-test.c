#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdbool.h>
#include <time.h>

#include "Hacl_Chacha20Poly1305_32.h"
#include "Hacl_Chacha20Poly1305_128.h"
#include "Hacl_Chacha20Poly1305_256.h"

#include "test_helpers.h"
#include "chacha20poly1305_vectors.h"


typedef uint64_t cycles;

static __inline__ cycles cpucycles_begin(void)
{
  uint64_t rax,rdx,aux;
  asm volatile ( "rdtscp\n" : "=a" (rax), "=d" (rdx), "=c" (aux) : : );
  return (rdx << 32) + rax;
  //  unsigned hi, lo;
  //__asm__ __volatile__ ("CPUID\n\t"  "RDTSC\n\t"  "mov %%edx, %0\n\t"  "mov %%eax, %1\n\t": "=r" (hi), "=r" (lo):: "%rax", "%rbx", "%rcx", "%rdx");
  //return ( (uint64_t)lo)|( ((uint64_t)hi)<<32 );
}

static __inline__ cycles cpucycles_end(void)
{
  uint64_t rax,rdx,aux;
  asm volatile ( "rdtscp\n" : "=a" (rax), "=d" (rdx), "=c" (aux) : : );
  return (rdx << 32) + rax;
  //  unsigned hi, lo;
  //__asm__ __volatile__ ("RDTSCP\n\t"  "mov %%edx, %0\n\t"  "mov %%eax, %1\n\t"  "CPUID\n\t": "=r" (hi), "=r" (lo)::     "%rax", "%rbx", "%rcx", "%rdx");
  //return ( (uint64_t)lo)|( ((uint64_t)hi)<<32 );
}

#define ROUNDS 100000
#define SIZE   16384

void print_time(clock_t tdiff, cycles cdiff){
  uint64_t count = ROUNDS * SIZE;
  printf("cycles for %" PRIu64 " bytes: %" PRIu64 " (%.2fcycles/byte)\n",count,(uint64_t)cdiff,(double)cdiff/count);
  printf("time for %" PRIu64 " bytes: %" PRIu64 " (%.2fus/byte)\n",count,(uint64_t)tdiff,(double)tdiff/count);
  printf("bw %8.2f MB/s\n",(double)count/(((double)tdiff / CLOCKS_PER_SEC) * 1000000.0));
}

bool print_result(int in_len, uint8_t* comp, uint8_t* exp) {
  return compare_and_print(in_len, comp, exp);
}

bool print_test(int in_len, uint8_t* in, uint8_t* key, uint8_t* nonce, int aad_len, uint8_t* aad, uint8_t* exp_mac, uint8_t* exp_cipher){
  uint8_t plaintext[in_len];
  memset(plaintext, 0, in_len * sizeof plaintext[0]);
  uint8_t ciphertext[in_len];
  memset(ciphertext, 0, in_len * sizeof ciphertext[0]);
  uint8_t mac[16] = {0};

  Hacl_Chacha20Poly1305_32_aead_encrypt(key, nonce, aad_len, aad, in_len, in, ciphertext, mac);
  printf("Chacha20Poly1305 (32-bit) Result (chacha20):\n");
  bool ok = print_result(in_len,ciphertext,exp_cipher);
  printf("(poly1305):\n");
  ok = ok && print_result(16,mac,exp_mac);

  int res = Hacl_Chacha20Poly1305_32_aead_decrypt(key, nonce, aad_len, aad, in_len, plaintext, exp_cipher, exp_mac);
  if (res != 0) printf("AEAD Decrypt (Chacha20/Poly1305) failed \n.");
  ok = ok && (res == 0);
  ok = ok && print_result(in_len,plaintext,in);


  Hacl_Chacha20Poly1305_128_aead_encrypt(key, nonce, aad_len, aad, in_len, in, ciphertext, mac);
  printf("Chacha20Poly1305 (128-bit) Result (chacha20):\n");
  ok = print_result(in_len,ciphertext,exp_cipher);
  printf("(poly1305):\n");
  ok = ok && print_result(16,mac,exp_mac);

  res = Hacl_Chacha20Poly1305_128_aead_decrypt(key, nonce, aad_len, aad, in_len, plaintext, exp_cipher, exp_mac);
  if (res != 0) printf("AEAD Decrypt (Chacha20/Poly1305) failed \n.");
  ok = ok && (res == 0);
  ok = ok && print_result(in_len,plaintext,in);


  Hacl_Chacha20Poly1305_256_aead_encrypt(key, nonce, aad_len, aad, in_len, in, ciphertext, mac);
  printf("Chacha20Poly1305 (256-bit) Result (chacha20):\n");
  ok = print_result(in_len,ciphertext,exp_cipher);
  printf("(poly1305):\n");
  ok = ok && print_result(16,mac,exp_mac);

  res = Hacl_Chacha20Poly1305_256_aead_decrypt(key, nonce, aad_len, aad, in_len, plaintext, exp_cipher, exp_mac);
  if (res != 0) printf("AEAD Decrypt (Chacha20/Poly1305) failed \n.");
  ok = ok && (res == 0);
  ok = ok && print_result(in_len,plaintext,in);

  return ok;
}

int main(){
  int in_len = vectors[0].input_len;
  uint8_t *in = vectors[0].input;
  uint8_t *aead_key = vectors[0].key;
  uint8_t *aead_nonce = vectors[0].nonce;
  int aad_len = vectors[0].aad_len;
  uint8_t *aead_aad = vectors[0].aad;
  uint8_t *exp_mac = vectors[0].tag;
  uint8_t *exp_cipher = vectors[0].cipher;

  bool ok = print_test(in_len,in,aead_key,aead_nonce,aad_len,aead_aad,exp_mac,exp_cipher);

  uint8_t plain[SIZE];
  uint8_t cipher[SIZE];
  int res = 0;
  uint8_t tag[16];
  cycles a,b;
  clock_t t1,t2;
  uint64_t count = ROUNDS * SIZE;

  memset(plain,'P',SIZE);
  memset(aead_key,'K',32);
  for (int j = 0; j < ROUNDS; j++) {
    Hacl_Chacha20Poly1305_32_aead_encrypt(aead_key, aead_nonce, aad_len, aead_aad, SIZE, plain, cipher, tag);
  }

  t1 = clock();
  a = cpucycles_begin();
  for (int j = 0; j < ROUNDS; j++) {
    Hacl_Chacha20Poly1305_32_aead_encrypt(aead_key, aead_nonce, aad_len, aead_aad, SIZE, plain, cipher, tag);
    res ^= tag[0] ^ tag[15];
  }
  b = cpucycles_end();
  t2 = clock();
  clock_t tdiff1 = t2 - t1;
  cycles cdiff1 = b - a;


  memset(plain,'P',SIZE);
  memset(aead_key,'K',32);
  for (int j = 0; j < ROUNDS; j++) {
    Hacl_Chacha20Poly1305_128_aead_encrypt(aead_key, aead_nonce, aad_len, aead_aad, SIZE, plain, cipher, tag);
  }

  t1 = clock();
  a = cpucycles_begin();
  for (int j = 0; j < ROUNDS; j++) {
    Hacl_Chacha20Poly1305_128_aead_encrypt(aead_key, aead_nonce, aad_len, aead_aad, SIZE, plain, cipher, tag);
    res ^= tag[0] ^ tag[15];
  }
  b = cpucycles_end();
  t2 = clock();
  clock_t tdiff2 = t2 - t1;
  cycles cdiff2 = b - a;


  memset(plain,'P',SIZE);
  memset(aead_key,'K',32);
  for (int j = 0; j < ROUNDS; j++) {
    Hacl_Chacha20Poly1305_256_aead_encrypt(aead_key, aead_nonce, aad_len, aead_aad, SIZE, plain, cipher, tag);
  }

  t1 = clock();
  a = cpucycles_begin();
  for (int j = 0; j < ROUNDS; j++) {
    Hacl_Chacha20Poly1305_256_aead_encrypt(aead_key, aead_nonce, aad_len, aead_aad, SIZE, plain, cipher, tag);
    res ^= tag[0] ^ tag[15];
  }
  b = cpucycles_end();
  t2 = clock();
  clock_t tdiff3 = t2 - t1;
  cycles cdiff3 = b - a;


  int res1 = 0;
  for (int j = 0; j < ROUNDS; j++) {
    res1 = Hacl_Chacha20Poly1305_32_aead_decrypt(aead_key, aead_nonce, aad_len, aead_aad, SIZE, plain, cipher, tag);
    res1 ^= res1;
  }

  res1 = 0;
  t1 = clock();
  a = cpucycles_begin();
  for (int j = 0; j < ROUNDS; j++) {
    Hacl_Chacha20Poly1305_32_aead_decrypt(aead_key, aead_nonce, aad_len, aead_aad, SIZE, plain, cipher, tag);
    res1 ^= res1;
  }
  b = cpucycles_end();
  t2 = clock();
  clock_t tdiff4 = t2 - t1;
  cycles cdiff4 = b - a;


  res1 = 0;
  for (int j = 0; j < ROUNDS; j++) {
    res1 = Hacl_Chacha20Poly1305_128_aead_decrypt(aead_key, aead_nonce, aad_len, aead_aad, SIZE, plain, cipher, tag);
    res1 ^= res1;
  }

  res1 = 0;
  t1 = clock();
  a = cpucycles_begin();
  for (int j = 0; j < ROUNDS; j++) {
    Hacl_Chacha20Poly1305_128_aead_decrypt(aead_key, aead_nonce, aad_len, aead_aad, SIZE, plain, cipher, tag);
    res1 ^= res1;
  }
  b = cpucycles_end();
  t2 = clock();
  clock_t tdiff5 = t2 - t1;
  cycles cdiff5 = b - a;


  res1 = 0;
  for (int j = 0; j < ROUNDS; j++) {
    res1 = Hacl_Chacha20Poly1305_256_aead_decrypt(aead_key, aead_nonce, aad_len, aead_aad, SIZE, plain, cipher, tag);
    res1 ^= res1;
  }

  res1 = 0;
  t1 = clock();
  a = cpucycles_begin();
  for (int j = 0; j < ROUNDS; j++) {
    Hacl_Chacha20Poly1305_256_aead_decrypt(aead_key, aead_nonce, aad_len, aead_aad, SIZE, plain, cipher, tag);
    res1 ^= res1;
  }
  b = cpucycles_end();
  t2 = clock();
  clock_t tdiff6 = t2 - t1;
  cycles cdiff6 = b - a;
  printf ("\n res1: %i \n", res1);


  printf("Chacha20Poly1305 Encrypt (32-bit) PERF:\n");  print_time(tdiff1,cdiff1);
  printf("Chacha20Poly1305 Encrypt (128-bit) PERF:\n"); print_time(tdiff2,cdiff2);
  printf("Chacha20Poly1305 Encrypt (256-bit) PERF:\n"); print_time(tdiff3,cdiff3);
  printf("Chacha20Poly1305 Decrypt (32-bit) PERF:\n");  print_time(tdiff4,cdiff4);
  printf("Chacha20Poly1305 Decrypt (128-bit) PERF:\n"); print_time(tdiff5,cdiff5);
  printf("Chacha20Poly1305 Decrypt (256-bit) PERF:\n"); print_time(tdiff6,cdiff6);

  if (ok) return EXIT_SUCCESS;
  else return EXIT_FAILURE;
}
